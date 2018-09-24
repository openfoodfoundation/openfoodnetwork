class AddUniquenessOfVariantIdToSpreeStockItems < ActiveRecord::Migration
  def change
    add_index :spree_stock_items, :variant_id, unique: true
  end
end
