class AddCascadingDeletes < ActiveRecord::Migration[4.2]
  def change
    # Updates foreign key definitions between orders, shipments, and inventory_units
    # to allow for cascading deletes at database level. If an order is intentionally
    # deleted *without callbacks*, it's shipments and inventory units will be removed
    # cleanly without throwing foreign key errors.

    remove_foreign_key :spree_shipments, name: "spree_shipments_order_id_fk"
    add_foreign_key :spree_shipments, :spree_orders, column: 'order_id',
                    name: 'spree_shipments_order_id_fk', on_delete: :cascade

    remove_foreign_key :spree_inventory_units, name: 'spree_inventory_units_shipment_id_fk'
    add_foreign_key :spree_inventory_units, :spree_shipments, column: 'shipment_id',
                    name: 'spree_inventory_units_shipment_id_fk', on_delete: :cascade

    remove_foreign_key :spree_inventory_units, name: 'spree_inventory_units_order_id_fk'
    add_foreign_key :spree_inventory_units, :spree_orders, column: 'order_id',
                    name: 'spree_inventory_units_order_id_fk', on_delete: :cascade
  end
end
