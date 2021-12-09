# frozen_string_literal: true

# Adapted from: https://www.kevin-custer.com/blog/migrate-a-rails-project-from-paperclip-to-active-storage/ .
# Other resources:
# - https://www.elitmus.com/blog/technology/migration-from-paperclip-to-activestorage/ (more up to date with rails 6,
# interesting discussions on potential bugs)
# - https://github.com/thoughtbot/paperclip/blob/master/MIGRATING.md
# - https://edgeguides.rubyonrails.org/active_storage_overview.html
require 'open-uri'

## Current models and corresponding attachments:
# Paperclip attachment columns found for [Enterprise]: ["logo", "promo_image", "terms_and_conditions"]
# Paperclip attachment columns found for [EnterpriseGroup]: ["promo_image", "logo"]
# Paperclip attachment columns found for [TermsOfServiceFile]: ["attachment"]
# Paperclip attachment columns found for [Spree::Image]: ["attachment"]
# Paperclip attachment columns found for [Spree::Taxon]: ["icon"]
#
# Duplicate from Spree::Image -> Paperclip attachment columns found for [Spree::Asset]: ["attachment"]

namespace :migrate_paperclip do
  desc 'Migrate Paperclip metadata to ActiveStorage metadata'
  task move_data: :environment do
    Rails.logger = Logger.new($stdout) # debug

    # Eager load the application so that all Models are available
    Rails.application.eager_load!

    # Get a list of all the models in the application.
    # Skip Spree::Asset as it has only one descendant Spree::Image and the attachment is defined in it, not in Asset.
    models = ActiveRecord::Base.descendants
      .reject(&:abstract_class?)
      .reject { |klass| klass == Spree::Asset }

    # Loop through all the models found
    models.each do |model|
      Rails.logger.debug "Checking Model [#{model}] for Paperclip attachment columns ..."

      # If the model has a column or columns named *_file_name,
      # We are assuming this is a column added by Paperclip.
      # Store the name of the attachment(s) found (e.g. "avatar") in an array named attachments
      attachments = model.column_names.map do |c|
        Regexp.last_match(1) if c =~ /(.+)_file_name$/
      end.compact

      # If no Paperclip columns were found in this model, go to the next model
      if attachments.blank?
        next
      end

      Rails.logger.debug "  Paperclip attachment columns found for [#{model}]: #{attachments}"

      # Loop through the records of the model, and then through each attachment definition within the model
      Rails.logger.debug "---> model: #{model}"
      model.find_each.each do |instance|
        attachments.each do |attachment|
          # If the model record doesn't have an uploaded attachment, skip to the next record
          next if instance.send(attachment).path.blank?

          Rails.logger.debug "    ---> instance: #{instance}, #{attachment}, #{instance.attachment.path}"

          # Otherwise, we will convert the Paperclip data to ActiveStorage records
          create_active_storage_records(instance, attachment, model)
        end
      end
    end
  end
end

private

def prepare_statements
  # Get the id of the last record inserted into active_storage_blobs
  # This will be used in the insert to active_storage_attachments
  # Postgres
  get_blob_id = 'LASTVAL()'
  # mariadb
  # get_blob_id = 'LAST_INSERT_ID()'
  # sqlite
  # get_blob_id = 'LAST_INSERT_ROWID()'

  # Prepare two insert statements for the new ActiveStorage tables
  ActiveRecord::Base.connection.raw_connection.prepare('active_storage_blob_statement', <<-SQL)
    INSERT INTO active_storage_blobs (
      key, filename, content_type, metadata, service_name, byte_size, checksum, created_at
    ) VALUES ($1, $2, $3, '{}', $4, $5, $6, $7)
  SQL

  ActiveRecord::Base.connection.raw_connection.prepare('active_storage_attachment_statement',
                                                       <<-SQL)
    INSERT INTO active_storage_attachments (
      name, record_type, record_id, blob_id, created_at
    ) VALUES ($1, $2, $3, #{get_blob_id}, $4)
  SQL
end

def create_active_storage_records(instance, attachment, model)
  Rails.logger.debug "    Creating ActiveStorage records for [#{model.name} (ID: #{instance.id})] #{instance.send("#{attachment}_file_name")} (#{instance.send("#{attachment}_content_type")})"

  # Set the values for the new ActiveStorage records based on the data from Paperclip's fields
  # for active_storage_blobs
  created_at = instance.send("#{attachment}_updated_at").iso8601
  blob_key = key(instance, attachment)
  filename = instance.send("#{attachment}_file_name")
  content_type = instance.send("#{attachment}_content_type")
  service_name = ActiveStorage::Blob.service.name
  file_size = instance.send("#{attachment}_file_size")
  file_checksum = checksum(instance.send(attachment))

  blob = ActiveStorage::Blob.find_or_create_by!(key: blob_key) do |blob|
    blob.created_at = created_at
    blob.filename = filename
    blob.content_type = content_type
    blob.metadata = {}
    blob.service_name = service_name
    blob.byte_size = file_size
    blob.checksum = file_checksum
  end

  Rails.logger.debug "        => created blob #{blob}"

  # Set the values for the new ActiveStorage records based on the data from Paperclip's fields
  # for active_storage_attachments
  activestorage_attachment = ActiveStorage::Attachment.find_or_create_by!(blob_id: blob.id) do |activestorage_attachment|
    activestorage_attachment.created_at = instance.send("#{attachment}_updated_at").iso8601
    activestorage_attachment.name = attachment
    activestorage_attachment.record_type = model.name
    activestorage_attachment.record_id = instance.id
  end

  Rails.logger.debug "        => created activestorage_attachment #{activestorage_attachment}"
end

def key(instance, attachment)
  # Get a new key
  # SecureRandom.uuid
  # Alternatively keep Paperclip path
  instance.send(attachment.to_s).path
end

def checksum(attachment)
  # Get a checksum for the file (required for ActiveStorage)

  # local files stored on disk:
  Digest::MD5.base64digest(File.read(attachment.path)) if attachment.path

  # remote files stored on a cloud service:
  Digest::MD5.base64digest(Net::HTTP.get(URI(attachment.url)))
end
