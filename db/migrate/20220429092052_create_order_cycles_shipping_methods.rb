class CreateOrderCyclesShippingMethods < ActiveRecord::Migration[6.1]
  def up
    create_table :order_cycles_shipping_methods, id: false do |t|
      t.belongs_to :order_cycle
      t.belongs_to :shipping_method, foreign_key: { to_table: :spree_shipping_methods }
      t.index [:order_cycle_id, :shipping_method_id],
        name: "order_cycles_shipping_methods_join_index",
        unique: true
    end
  end

  def down
    drop_table :order_cycles_shipping_methods
  end
end
