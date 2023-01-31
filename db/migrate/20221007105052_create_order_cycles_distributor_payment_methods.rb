class CreateOrderCyclesDistributorPaymentMethods < ActiveRecord::Migration[6.1]
  def change
    create_table :order_cycles_distributor_payment_methods, id: false do |t|
      t.belongs_to :order_cycle,
        index: { name: "index_oc_id_on_order_cycles_distributor_payment_methods" }
      t.belongs_to :distributor_payment_method,
        index: { name: "index_dpm_id_on_order_cycles_distributor_payment_methods" }
      t.index [:order_cycle_id, :distributor_payment_method_id],
        name: "order_cycles_distributor_payment_methods_join_index",
        unique: true
    end
  end
end
