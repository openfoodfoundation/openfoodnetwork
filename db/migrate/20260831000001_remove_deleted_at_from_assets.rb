# frozen_string_literal: true

# Undoes AddDeletedAtToAssets. Soft delete for images was a stop-gap while the
# single-product-image constraint was in flux; the soft-deleted rows are purged by
# PurgeSoftDeletedImages, which must run first.
class RemoveDeletedAtFromAssets < ActiveRecord::Migration[7.2]
  def change
    remove_index :spree_assets, :deleted_at
    remove_column :spree_assets, :deleted_at, :datetime
  end
end
