class CreateOrderCyclesDistributorShippingMethods < ActiveRecord::Migration[6.1]
  def up
    create_table :order_cycles_distributor_shipping_methods, id: false do |t|
      t.belongs_to :order_cycle,
        index: { name: "index_oc_id_on_order_cycles_distributor_shipping_methods" }
      t.belongs_to :distributor_shipping_method,
        index: { name: "index_dsm_id_on_order_cycles_distributor_shipping_methods" }
      t.index [:order_cycle_id, :distributor_shipping_method_id],
        name: "order_cycles_distributor_shipping_methods_join_index",
        unique: true
    end
  end

  def down
    drop_table :order_cycles_distributor_shipping_methods
  end
end
