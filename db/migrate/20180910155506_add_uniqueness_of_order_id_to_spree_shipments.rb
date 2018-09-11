class AddUniquenessOfOrderIdToSpreeShipments < ActiveRecord::Migration
  def change
    remove_index :spree_shipments, :order_id
    add_index :spree_shipments, :order_id, unique: true
  end
end
