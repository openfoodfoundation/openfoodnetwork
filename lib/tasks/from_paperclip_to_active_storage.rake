# frozen_string_literal: true

namespace :from_paperclip_to_active_storage do
  # This migration can't be a pure database migration because we need to know
  # the location of current files which is computed by Paperclip depending on
  # the `url` option.
  desc "Copy data to Active Storage tables referencing Paperclip files"
  task migrate: :environment do
    Rails.application.eager_load!

    HasMigratingFile.migrating_models.each do |model_name|
      puts "Migrating #{model_name}"
      migrate_model(model_name.constantize)
    end
  end

  # We have a special class called ContentConfiguration which is not a model
  # and therfore can't use the normal Active Storage magic.
  #
  # It uses `Spree::Preference`s to store all the Paperclip attributes. These
  # files are stored locally and we can replace them with preferences pointing
  # to an Active Storage blob.
  desc "Associate ContentConfig to ActiveStorage blobs"
  task copy_content_config: :environment do
    [
      :logo,
      :logo_mobile,
      :logo_mobile_svg,
      :home_hero,
      :footer_logo,
    ].each do |name|
      migrate_content_config_file(name)
    end
  end

  def migrate_model(model)
    duplicated_attachment_names(model).each do |name|
      migrate_attachment(model, name)
    end
  end

  def migrate_attachment(model, name)
    records_to_migrate = missing_active_storage_attachment(model, name)

    print " - #{name} (#{records_to_migrate.count}) "

    records_to_migrate.find_each do |record|
      attach_paperclip(name, record)
    end

    puts ""
  end

  def attach_paperclip(name, record)
    paperclip = record.public_send(name)

    if paperclip.respond_to?(:s3_object)
      attachment = storage_record_for(name, paperclip)
      record.public_send("#{name}_attachment=", attachment)
      print "."
    elsif File.exist?(paperclip.path)
      record.attach_file(name, File.open(paperclip.path))
      record.save!
      print "."
    else
      print "x"
    end
  rescue StandardError => e
    puts "x"
    puts e.message
  end

  # Creates an Active Storage record pointing to the same file Paperclip
  # stored on AWS S3. Getting the checksum requires a HEAD request.
  # In my tests, I could process 100 records per minute this way.
  def storage_record_for(name, paperclip)
    blob = ActiveStorage::Blob.new(
      key: paperclip.path(:original),
      filename: paperclip.original_filename,
      content_type: paperclip.content_type,
      metadata: {},
      byte_size: paperclip.size,
      checksum: paperclip.s3_object.etag,
      created_at: paperclip.updated_at,
    )
    ActiveStorage::Attachment.new(
      name: name,
      blob: blob,
      created_at: paperclip.updated_at,
    )
  end

  def migrate_content_config_file(name)
    paperclip = ContentConfig.public_send(name)

    return if ContentConfig.public_send("#{name}_blob_id")
    return if paperclip.path.blank? || !paperclip.exists?

    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(paperclip.path),
      filename: paperclip.original_filename,
      content_type: paperclip.content_type,
      identify: false,
    )

    ContentConfig.public_send("#{name}_blob_id=", blob.id)
    puts "Copied #{name}"
  end

  def duplicated_attachment_names(model)
    paperclip_attachments = model.attachment_definitions.keys.map(&:to_s)
    active_storage_attachments = model.attachment_reflections.keys

    only_paperclip = paperclip_attachments - active_storage_attachments
    only_active_storage = active_storage_attachments - paperclip_attachments
    both = paperclip_attachments & active_storage_attachments

    puts "WARNING: not migrating #{only_paperclip}" if only_paperclip.present?
    puts "WARNING: no source for #{only_active_storage}" if only_active_storage.present?

    both
  end

  # Records with Paperclip but without an Active storage attachment yet
  def missing_active_storage_attachment(model, attachment)
    model.where.not("#{attachment}_file_name" => [nil, ""]).
      left_outer_joins("#{attachment}_attachment".to_sym).
      where(active_storage_attachments: { id: nil })
  end
end
