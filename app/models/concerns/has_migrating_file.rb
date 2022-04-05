# frozen_string_literal: true

module HasMigratingFile
  extend ActiveSupport::Concern

  class_methods do
    def has_one_migrating(name, paperclip_options = {})
      # Active Storage declaration
      has_one_attached name

      # Backup Active Storage methods before they get overridden by Paperclip.
      alias_method "active_storage_#{name}", name
      alias_method "active_storage_#{name}=", "#{name}="

      # Paperclip declaration
      #
      # This will define the `name` and `name=` methods as well.
      has_attached_file name, paperclip_options

      # Paperclip callback to duplicate file with Active Storage
      #
      # We store files with Paperclip *and* Active Storage while we migrate
      # old Paperclip files to Active Storage. This enables availability
      # during the migration.
      public_send("after_#{name}_post_process") do
        path = processed_local_file_path(name)
        if public_send(name).errors.blank? && path.present?
          attach_file(name, File.open(path))
        end
      end
    end
  end

  def attach_file(name, io)
    attachable = {
      io: io,
      filename: public_send("#{name}_file_name"),
      content_type: public_send("#{name}_content_type"),
      identify: false,
    }
    public_send("active_storage_#{name}=", attachable)
  end

  private

  def processed_local_file_path(name)
    attachment = public_send(name)

    temporary = attachment.queued_for_write[:original]

    if temporary&.path.present?
      temporary.path
    else
      attachment.path
    end
  end
end
