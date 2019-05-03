# Since OFN has only a single default StockLocation, variants in OFN can only
# have a stock item. By adding this unique index we constraint that at DB level
# ensuring data integrity.
class AddUniquenessOfVariantIdToSpreeStockItems < ActiveRecord::Migration
  def change
    add_index :spree_stock_items, :variant_id, unique: true
  end
end
