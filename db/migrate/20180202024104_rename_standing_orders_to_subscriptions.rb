class RenameStandingOrdersToSubscriptions < ActiveRecord::Migration
  def up
    remove_foreign_key :proxy_orders, name: :standing_order_id_fk
    remove_foreign_key :standing_line_items, name: :oc_standing_line_items_standing_order_id_fk

    remove_foreign_key :standing_orders, name: :oc_standing_orders_customer_id_fk
    remove_foreign_key :standing_orders, name: :oc_standing_orders_shop_id_fk
    remove_foreign_key :standing_orders, name: :oc_standing_orders_schedule_id_fk
    remove_foreign_key :standing_orders, name: :standing_orders_bill_address_id_fk
    remove_foreign_key :standing_orders, name: :standing_orders_ship_address_id_fk
    remove_foreign_key :standing_orders, name: :standing_orders_credit_card_id_fk
    remove_foreign_key :standing_orders, name: :oc_standing_orders_payment_method_id_fk
    remove_foreign_key :standing_orders, name: :oc_standing_orders_shipping_method_id_fk

    remove_index :proxy_orders, :column => [:order_cycle_id, :standing_order_id]
    remove_index :proxy_orders, :column => [:standing_order_id]
    remove_index :standing_line_items, :column => [:standing_order_id]

    rename_table :standing_orders, :subscriptions

    rename_index :subscriptions, :index_standing_orders_on_bill_address_id, :index_subscriptions_on_bill_address_id
    rename_index :subscriptions, :index_standing_orders_on_credit_card_id, :index_subscriptions_on_credit_card_id
    rename_index :subscriptions, :index_standing_orders_on_customer_id, :index_subscriptions_on_customer_id
    rename_index :subscriptions, :index_standing_orders_on_payment_method_id, :index_subscriptions_on_payment_method_id
    rename_index :subscriptions, :index_standing_orders_on_schedule_id, :index_subscriptions_on_schedule_id
    rename_index :subscriptions, :index_standing_orders_on_ship_address_id, :index_subscriptions_on_ship_address_id
    rename_index :subscriptions, :index_standing_orders_on_shipping_method_id, :index_subscriptions_on_shipping_method_id
    rename_index :subscriptions, :index_standing_orders_on_shop_id, :index_subscriptions_on_shop_id

    rename_column :enterprises, :enable_standing_orders, :enable_subscriptions
    rename_column :proxy_orders, :standing_order_id, :subscription_id
    rename_column :standing_line_items, :standing_order_id, :subscription_id

    add_index :proxy_orders, [:order_cycle_id, :subscription_id], unique: true
    add_index :proxy_orders, :subscription_id
    add_index :standing_line_items, :subscription_id

    add_foreign_key :proxy_orders, :subscriptions, name: :proxy_orders_subscription_id_fk
    add_foreign_key :standing_line_items, :subscriptions, name: :standing_line_items_subscription_id_fk

    add_foreign_key :subscriptions, :customers, name: :subscriptions_customer_id_fk
    add_foreign_key :subscriptions, :enterprises, name: :subscriptions_shop_id_fk, column: :shop_id
    add_foreign_key :subscriptions, :schedules, name: :subscriptions_schedule_id_fk
    add_foreign_key :subscriptions, :spree_addresses, name: :subscriptions_bill_address_id_fk, column: :bill_address_id
    add_foreign_key :subscriptions, :spree_addresses, name: :subscriptions_ship_address_id_fk, column: :ship_address_id
    add_foreign_key :subscriptions, :spree_credit_cards, name: :subscriptions_credit_card_id_fk, column: :credit_card_id
    add_foreign_key :subscriptions, :spree_payment_methods, name: :subscriptions_payment_method_id_fk, column: :payment_method_id
    add_foreign_key :subscriptions, :spree_shipping_methods, name: :subscriptions_shipping_method_id_fk, column: :shipping_method_id
  end

  def down
    remove_foreign_key :proxy_orders, name: :proxy_orders_subscription_id_fk
    remove_foreign_key :standing_line_items, name: :standing_line_items_subscription_id_fk

    remove_foreign_key :subscriptions, name: :subscriptions_customer_id_fk
    remove_foreign_key :subscriptions, name: :subscriptions_shop_id_fk
    remove_foreign_key :subscriptions, name: :subscriptions_schedule_id_fk
    remove_foreign_key :subscriptions, name: :subscriptions_bill_address_id_fk
    remove_foreign_key :subscriptions, name: :subscriptions_ship_address_id_fk
    remove_foreign_key :subscriptions, name: :subscriptions_credit_card_id_fk
    remove_foreign_key :subscriptions, name: :subscriptions_payment_method_id_fk
    remove_foreign_key :subscriptions, name: :subscriptions_shipping_method_id_fk

    remove_index :proxy_orders, :column => [:order_cycle_id, :subscription_id]
    remove_index :proxy_orders, :column => [:subscription_id]
    remove_index :standing_line_items, :column => [:subscription_id]

    rename_table :subscriptions, :standing_orders

    rename_index :standing_orders, :index_subscriptions_on_bill_address_id, :index_standing_orders_on_bill_address_id
    rename_index :standing_orders, :index_subscriptions_on_credit_card_id, :index_standing_orders_on_credit_card_id
    rename_index :standing_orders, :index_subscriptions_on_customer_id, :index_standing_orders_on_customer_id
    rename_index :standing_orders, :index_subscriptions_on_payment_method_id, :index_standing_orders_on_payment_method_id
    rename_index :standing_orders, :index_subscriptions_on_schedule_id, :index_standing_orders_on_schedule_id
    rename_index :standing_orders, :index_subscriptions_on_ship_address_id, :index_standing_orders_on_ship_address_id
    rename_index :standing_orders, :index_subscriptions_on_shipping_method_id, :index_standing_orders_on_shipping_method_id
    rename_index :standing_orders, :index_subscriptions_on_shop_id, :index_standing_orders_on_shop_id

    rename_column :enterprises, :enable_subscriptions, :enable_standing_orders
    rename_column :proxy_orders, :subscription_id, :standing_order_id
    rename_column :standing_line_items, :subscription_id, :standing_order_id

    add_index :proxy_orders, [:order_cycle_id, :standing_order_id], unique: true
    add_index :proxy_orders, :standing_order_id
    add_index :standing_line_items, :standing_order_id

    add_foreign_key :proxy_orders, :standing_orders, name: :standing_order_id_fk
    add_foreign_key :standing_line_items, :standing_orders, name: :oc_standing_line_items_standing_order_id_fk

    add_foreign_key :standing_orders, :customers, name: :oc_standing_orders_customer_id_fk
    add_foreign_key :standing_orders, :enterprises, name: :oc_standing_orders_shop_id_fk, column: :shop_id
    add_foreign_key :standing_orders, :schedules, name: :oc_standing_orders_schedule_id_fk
    add_foreign_key :standing_orders, :spree_addresses, name: :standing_orders_bill_address_id_fk, column: :bill_address_id
    add_foreign_key :standing_orders, :spree_addresses, name: :standing_orders_ship_address_id_fk, column: :ship_address_id
    add_foreign_key :standing_orders, :spree_credit_cards, name: :standing_orders_credit_card_id_fk, column: :credit_card_id
    add_foreign_key :standing_orders, :spree_payment_methods, name: :oc_standing_orders_payment_method_id_fk, column: :payment_method_id
    add_foreign_key :standing_orders, :spree_shipping_methods, name: :oc_standing_orders_shipping_method_id_fk, column: :shipping_method_id
  end
end
