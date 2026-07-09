# frozen_string_literal: true

class RemoveExistingVariantImages < ActiveRecord::Migration[7.2]
  module Spree
    class Asset < ActiveRecord::Base
      # This class is to allow the migration to reference the Spree::Asset in record_type.
      self.table_name = "spree_assets"
      self.inheritance_column = :_type_disabled
    end
  end

  class SpreeImage < Spree::Asset
    has_one :attachment_record,
            -> { where(name: "attachment", record_type: "Spree::Asset") },
            class_name: "ActiveStorage::Attachment",
            foreign_key: :record_id,
            primary_key: :id

    has_one :blob,
            through: :attachment_record,
            source: :blob
  end

  def up
    SpreeImage
      .where(type: "Spree::Image", viewable_type: "Spree::Variant")
      .find_each do |image|
        attachment = image.attachment_record
        next unless attachment

        blob = attachment.blob

        attachment.destroy!

        blob.purge if blob.attachments.none?

        image.destroy!
        Rails.logger.info("Removed image ##{image.id} and its associated attachment and blob.")
      rescue StandardError => e
        Rails.logger.error("Failed to remove image ##{image.id}: #{e.message}")
      end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
