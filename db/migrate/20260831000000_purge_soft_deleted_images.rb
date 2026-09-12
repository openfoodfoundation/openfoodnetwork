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
    failed_batches = []

    Asset.where.not(deleted_at: nil).in_batches do |batch|
      ids = batch.ids

      purge_batch(ids)
    rescue StandardError => e
      # Don't let one bad batch abort the rest of the purge, but don't lose it either:
      # RemoveDeletedAtFromAssets drops deleted_at right after this migration, so a
      # silently skipped batch would be unrecoverable. Record it and re-raise below so
      # the migration fails, deleted_at survives, and the (idempotent) purge can re-run.
      failed_batches << "##{ids.first}-##{ids.last}"
      Rails.logger.error(
        "Failed to purge soft-deleted images (batch ##{ids.first}-##{ids.last}): " \
        "#{e.class}: #{e.message}"
      )
    end

    return if failed_batches.empty?

    raise "PurgeSoftDeletedImages failed for #{failed_batches.size} batch(es): " \
          "#{failed_batches.join(', ')}. deleted_at is preserved; re-run after fixing."
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

    attachment_count = 0
    asset_count = 0
    ActiveRecord::Base.transaction do
      attachment_count = attachments.delete_all
      asset_count = Asset.where(id: ids).delete_all
    end

    ActiveStorage::Blob.where(id: blob_ids).find_each(&:purge_later)

    Rails.logger.info(
      "Purged #{asset_count} soft-deleted image(s), #{attachment_count} attachment(s) " \
      "and enqueued #{blob_ids.size} blob(s) for purge."
    )
  end
end
