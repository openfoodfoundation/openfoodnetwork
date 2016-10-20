class CreateStandingOrderOrders < ActiveRecord::Migration
  def change
    create_table :standing_order_orders do |t|
      t.references :standing_order, null: false
      t.references :order, null: false
      t.datetime :cancelled_at
      t.timestamps
    end

    add_index :standing_order_orders, :standing_order_id
    add_index :standing_order_orders, :order_id, unique: true

    add_foreign_key "standing_order_orders", "standing_orders", name: "standing_order_id_fk", column: "standing_order_id"
    add_foreign_key "standing_order_orders", "spree_orders", name: "order_id_fk", column: "order_id"
  end
end
