class AddBillAddressAndShipAddressToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :bill_address_id, :integer
    add_column :customers, :ship_address_id, :integer

    add_index :customers, :bill_address_id
    add_index :customers, :ship_address_id

    add_foreign_key :customers, :spree_addresses, column: :bill_address_id
    add_foreign_key :customers, :spree_addresses, column: :ship_address_id
  end
end
