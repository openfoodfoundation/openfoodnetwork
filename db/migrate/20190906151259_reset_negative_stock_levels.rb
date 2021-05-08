class ResetNegativeStockLevels < ActiveRecord::Migration[4.2]
  def up
    # Reset stock to zero for all on_demand variants that have negative stock
    execute "UPDATE spree_stock_items SET count_on_hand = '0' WHERE count_on_hand < 0 AND backorderable IS TRUE"
  end
end
