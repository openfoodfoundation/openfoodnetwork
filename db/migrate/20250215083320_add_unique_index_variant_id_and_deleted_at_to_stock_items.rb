# frozen_string_literal: true

class AddUniqueIndexVariantIdAndDeletedAtToStockItems < ActiveRecord::Migration[7.0]
  def change
    remove_index :spree_stock_items, :variant_id, name: :index_spree_stock_items_on_variant_id
    add_index(:spree_stock_items, [:variant_id, :deleted_at], unique: true)
  end
end
