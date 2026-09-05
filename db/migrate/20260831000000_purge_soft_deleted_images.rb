# frozen_string_literal: true

# Images used to be soft-deleted so that a single-product-image constraint could be
# enforced before multi-image backoffice support was ready. Nothing ever read those
# rows back, and the model deliberately suppressed ActiveStorage's dependent-purge,
# so every soft-deleted image left a spree_assets row, an attachment row and a blob
# behind. Now that soft delete is gone, remove them for good.
#
# This has to run before deleted_at is dropped: that column is the only way to tell
# these rows apart from live images.
class PurgeSoftDeletedImages < ActiveRecord::Migration[7.2]
  class Asset < ActiveRecord::Base
    self.table_name = "spree_assets"
    self.inheritance_column = :_type_disabled
  end

  class Attachment < ActiveRecord::Base
    self.table_name = "active_storage_attachments"
  end

  def up
    Asset.where.not(deleted_at: nil).in_batches do |batch|
      ids = batch.ids

      purge_batch(ids)
    rescue StandardError => e
      # One bad batch must not abort the purge. Note that RemoveDeletedAtFromAssets
      # drops deleted_at right after this migration, so a skipped batch becomes
      # indistinguishable from live images: this log line is the only record of it.
      Rails.logger.error(
        "Failed to purge soft-deleted images (batch ##{ids.first}-##{ids.last}): " \
        "#{e.class}: #{e.message}"
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def purge_batch(ids)
    attachments = Attachment.where(
      name: "attachment", record_type: "Spree::Asset", record_id: ids
    )
    blob_ids = attachments.distinct.pluck(:blob_id)

    attachment_count = attachments.delete_all
    asset_count = Asset.where(id: ids).delete_all

    orphan_ids = blob_ids - Attachment.where(blob_id: blob_ids).distinct.pluck(:blob_id)
    ActiveStorage::Blob.where(id: orphan_ids).find_each(&:purge_later)

    Rails.logger.info(
      "Purged #{asset_count} soft-deleted image(s), #{attachment_count} attachment(s) " \
      "and enqueued #{orphan_ids.size} orphaned blob(s) for purge."
    )
  end
end
