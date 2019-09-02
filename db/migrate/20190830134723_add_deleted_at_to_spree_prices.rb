class AddDeletedAtToSpreePrices < ActiveRecord::Migration
  def change
    add_column :spree_prices, :deleted_at, :datetime
    add_index :spree_prices, :deleted_at
  end
end
