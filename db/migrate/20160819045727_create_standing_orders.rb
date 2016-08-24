class CreateStandingOrders < ActiveRecord::Migration
  def change
    create_table :standing_orders do |t|
      t.references :shop, null: false
      t.references :customer, null: false
      t.references :schedule, null: false
      t.references :payment_method, null: false
      t.references :shipping_method, null: false
      t.datetime :begins_at, :ends_at
      t.timestamps
    end

    add_index :standing_orders, :shop_id
    add_index :standing_orders, :customer_id
    add_index :standing_orders, :schedule_id
    add_index :standing_orders, :payment_method_id
    add_index :standing_orders, :shipping_method_id

    add_foreign_key :standing_orders, :enterprises, name: 'oc_standing_orders_shop_id_fk', column: :shop_id
    add_foreign_key :standing_orders, :customers, name: 'oc_standing_orders_customer_id_fk'
    add_foreign_key :standing_orders, :schedules, name: 'oc_standing_orders_schedule_id_fk'
    add_foreign_key :standing_orders, :spree_payment_methods, name: 'oc_standing_orders_payment_method_id_fk', column: :payment_method_id
    add_foreign_key :standing_orders, :spree_shipping_methods, name: 'oc_standing_orders_shipping_method_id_fk', column: :shipping_method_id
  end
end
