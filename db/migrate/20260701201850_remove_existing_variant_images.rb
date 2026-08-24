# frozen_string_literal: true

class RemoveExistingVariantImages < ActiveRecord::Migration[7.2]
  class Asset < ActiveRecord::Base
    self.table_name = "spree_assets"
    self.inheritance_column = :_type_disabled
  end

  class Attachment < ActiveRecord::Base
    self.table_name = "active_storage_attachments"
  end

  def up # rubocop:disable Metrics/MethodLength
    Asset
      .where(type: "Spree::Image", viewable_type: "Spree::Variant")
      .find_each do |image|
      attachment = Attachment.find_by(
        name: "attachment",
        record_type: "Spree::Asset",
        record_id: image.id
      )

      unless attachment
        image.destroy!
        next
      end

      blob_id = attachment.blob_id

      attachment.destroy!
      image.destroy!

      if !Attachment.where(blob_id: blob_id).exists?
        ActiveStorage::Blob.find_by(id: blob_id)&.purge_later
      end

      Rails.logger.info(
        "Removed image ##{image.id} and its associated attachment and blob."
      )
    rescue StandardError => e
      Rails.logger.error(
        "Failed to remove image ##{image.id}: #{e.class}: #{e.message}"
      )
    end
  end # rubocop:enable Metrics/MethodLength

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
