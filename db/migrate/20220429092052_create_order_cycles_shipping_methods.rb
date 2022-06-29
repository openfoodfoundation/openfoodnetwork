class CreateOrderCycleShippingMethods < ActiveRecord::Migration[6.1]
  def up
    create_table :order_cycles_shipping_methods, id: false do |t|
      t.references :order_cycle
      t.references :shipping_method, foreign_key: { to_table: :spree_shipping_methods }
    end
    add_index :order_cycles_shipping_methods,
      [:order_cycle_id, :shipping_method_id],
      name: "order_cycles_shipping_methods_join_index",
      unique: true
  end

  def down
    drop_table :order_cycles_shipping_methods
  end
end
