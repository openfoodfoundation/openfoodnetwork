class DropUnusedTables < ActiveRecord::Migration[7.0]
  def up
    drop_table :spree_stock_transfers
    drop_table :spree_product_scopes
    drop_table :spree_pending_promotions
    drop_table :spree_activators
    drop_table :delayed_jobs
  end
end
