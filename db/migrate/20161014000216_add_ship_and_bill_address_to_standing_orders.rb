class AddShipAndBillAddressToStandingOrders < ActiveRecord::Migration
  def change
    add_column :standing_orders, :bill_address_id, :integer, null: false
    add_column :standing_orders, :ship_address_id, :integer, null: false

    add_index :standing_orders, :bill_address_id
    add_index :standing_orders, :ship_address_id

    add_foreign_key :standing_orders, :spree_addresses, column: :bill_address_id
    add_foreign_key :standing_orders, :spree_addresses, column: :ship_address_id
  end
end
