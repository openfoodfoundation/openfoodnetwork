require 'open-uri'

namespace :migrate_paperclip do
  desc 'Migrate the paperclip data'
  task move_data: :environment do
    prepare_statements
    Rails.application.eager_load!

    models = ActiveRecord::Base.descendants.reject(&:abstract_class?)

    models.each do |model|
      puts 'Checking Model [' + model.to_s + '] for Paperclip attachment columns ...'

      attachments = model.column_names.map do |c|
        Regexp.last_match(1) if c =~ /(.+)_file_name$/
      end.compact

      if attachments.blank?
        puts '  No Paperclip attachment columns found for [' + model.to_s + '].'
        puts ''
        next
      end

      puts '  Paperclip attachment columns found for [' + model.to_s + ']: ' + attachments.to_s

      model.find_each.each do |instance|
        attachments.each do |attachment|
          next if instance.send(attachment).path.blank?

          create_active_storage_records(instance, attachment, model)
        end
      end
      puts ''
    end
  end
end

private

def prepare_statements
  get_blob_id = 'LASTVAL()'

  ActiveRecord::Base.connection.raw_connection.prepare('active_storage_blob_statement', <<-SQL)
    INSERT INTO active_storage_blobs (
      key, filename, content_type, metadata, byte_size, checksum, created_at
    ) VALUES ($1, $2, $3, '{}', $4, $5, $6)
  SQL

  ActiveRecord::Base.connection.raw_connection.prepare('active_storage_attachment_statement', <<-SQL)
    INSERT INTO active_storage_attachments (
      name, record_type, record_id, blob_id, created_at
    ) VALUES ($1, $2, $3, #{get_blob_id}, $4)
  SQL
end

def create_active_storage_records(instance, attachment, model)
  puts '    Creating ActiveStorage records for [' +
       model.name + ' (ID: ' + instance.id.to_s + ')] ' +
       instance.send("#{attachment}_file_name") +
       ' (' + instance.send("#{attachment}_content_type") + ')'
  build_active_storage_blob(instance, attachment)
  build_active_storage_attachment(instance, attachment, model)
end

def build_active_storage_blob(instance, attachment)
  created_at = instance.updated_at.iso8601
  blob_key = key(instance, attachment)
  filename = instance.send("#{attachment}_file_name")
  content_type = instance.send("#{attachment}_content_type")
  file_size = instance.send("#{attachment}_file_size")
  file_checksum = checksum(instance.send(attachment))

  blob_values = [blob_key, filename, content_type, file_size, file_checksum, created_at]

  insert_record('active_storage_blob_statement', blob_values)
end

def build_active_storage_attachment(instance, attachment, model)
  created_at = instance.updated_at.iso8601
  blob_name = attachment
  record_type = model.name
  record_id = instance.id
  attachment_values = [blob_name, record_type, record_id, created_at]

  insert_record('active_storage_attachment_statement', attachment_values)
end

def insert_record(statement, values)
  ActiveRecord::Base.connection.raw_connection.exec_prepared(
    statement,
    values
  )
end

def key(_instance, _attachment)
  SecureRandom.uuid
end

def checksum(attachment)
  url = attachment.url
  Digest::MD5.base64digest(Net::HTTP.get(URI(url)))
end
