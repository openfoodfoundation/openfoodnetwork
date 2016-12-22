class AddPlacedAtAndConfirmedAtToProxyOrders < ActiveRecord::Migration
  def change
    add_column :proxy_orders, :placed_at, :datetime
    add_column :proxy_orders, :confirmed_at, :datetime
  end
end
