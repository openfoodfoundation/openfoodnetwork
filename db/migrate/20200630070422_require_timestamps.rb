class RequireTimestamps < ActiveRecord::Migration[4.2]
  def up
    current_time = Time.zone.now

    change_column_null :customers, :created_at, false, current_time
    change_column_null :customers, :updated_at, false, current_time
    change_column_null :delayed_jobs, :created_at, false, current_time
    change_column_null :delayed_jobs, :updated_at, false, current_time
    change_column_null :distributors_shipping_methods, :created_at, false, current_time
    change_column_null :distributors_shipping_methods, :updated_at, false, current_time
    change_column_null :enterprise_fees, :created_at, false, current_time
    change_column_null :enterprise_fees, :updated_at, false, current_time
    change_column_null :enterprises, :created_at, false, current_time
    change_column_null :enterprises, :updated_at, false, current_time
    change_column_null :exchange_fees, :created_at, false, current_time
    change_column_null :exchange_fees, :updated_at, false, current_time
    change_column_null :exchange_variants, :created_at, false, current_time
    change_column_null :exchange_variants, :updated_at, false, current_time
    change_column_null :exchanges, :created_at, false, current_time
    change_column_null :exchanges, :updated_at, false, current_time
    change_column_null :inventory_items, :created_at, false, current_time
    change_column_null :inventory_items, :updated_at, false, current_time
    change_column_null :order_cycle_schedules, :created_at, false, current_time
    change_column_null :order_cycle_schedules, :updated_at, false, current_time
    change_column_null :order_cycles, :created_at, false, current_time
    change_column_null :order_cycles, :updated_at, false, current_time
    change_column_null :producer_properties, :created_at, false, current_time
    change_column_null :producer_properties, :updated_at, false, current_time
    change_column_null :proxy_orders, :created_at, false, current_time
    change_column_null :proxy_orders, :updated_at, false, current_time
    change_column_null :schedules, :created_at, false, current_time
    change_column_null :schedules, :updated_at, false, current_time
    change_column_null :sessions, :created_at, false, current_time
    change_column_null :sessions, :updated_at, false, current_time
    change_column_null :spree_activators, :created_at, false, current_time
    change_column_null :spree_activators, :updated_at, false, current_time
    change_column_null :spree_addresses, :created_at, false, current_time
    change_column_null :spree_addresses, :updated_at, false, current_time
    change_column_null :spree_adjustments, :created_at, false, current_time
    change_column_null :spree_adjustments, :updated_at, false, current_time
    change_column_null :spree_calculators, :created_at, false, current_time
    change_column_null :spree_calculators, :updated_at, false, current_time
    change_column_null :spree_configurations, :created_at, false, current_time
    change_column_null :spree_configurations, :updated_at, false, current_time
    change_column_null :spree_credit_cards, :created_at, false, current_time
    change_column_null :spree_credit_cards, :updated_at, false, current_time
    change_column_null :spree_gateways, :created_at, false, current_time
    change_column_null :spree_gateways, :updated_at, false, current_time
    change_column_null :spree_inventory_units, :created_at, false, current_time
    change_column_null :spree_inventory_units, :updated_at, false, current_time
    change_column_null :spree_line_items, :created_at, false, current_time
    change_column_null :spree_line_items, :updated_at, false, current_time
    change_column_null :spree_log_entries, :created_at, false, current_time
    change_column_null :spree_log_entries, :updated_at, false, current_time
    change_column_null :spree_option_types, :created_at, false, current_time
    change_column_null :spree_option_types, :updated_at, false, current_time
    change_column_null :spree_option_values, :created_at, false, current_time
    change_column_null :spree_option_values, :updated_at, false, current_time
    change_column_null :spree_orders, :created_at, false, current_time
    change_column_null :spree_orders, :updated_at, false, current_time
    change_column_null :spree_payment_methods, :created_at, false, current_time
    change_column_null :spree_payment_methods, :updated_at, false, current_time
    change_column_null :spree_payments, :created_at, false, current_time
    change_column_null :spree_payments, :updated_at, false, current_time
    change_column_null :spree_preferences, :created_at, false, current_time
    change_column_null :spree_preferences, :updated_at, false, current_time
    change_column_null :spree_product_option_types, :created_at, false, current_time
    change_column_null :spree_product_option_types, :updated_at, false, current_time
    change_column_null :spree_product_properties, :created_at, false, current_time
    change_column_null :spree_product_properties, :updated_at, false, current_time
    change_column_null :spree_products, :created_at, false, current_time
    change_column_null :spree_products, :updated_at, false, current_time
    change_column_null :spree_promotion_rules, :created_at, false, current_time
    change_column_null :spree_promotion_rules, :updated_at, false, current_time
    change_column_null :spree_properties, :created_at, false, current_time
    change_column_null :spree_properties, :updated_at, false, current_time
    change_column_null :spree_return_authorizations, :created_at, false, current_time
    change_column_null :spree_return_authorizations, :updated_at, false, current_time
    change_column_null :spree_shipments, :created_at, false, current_time
    change_column_null :spree_shipments, :updated_at, false, current_time
    change_column_null :spree_shipping_categories, :created_at, false, current_time
    change_column_null :spree_shipping_categories, :updated_at, false, current_time
    change_column_null :spree_shipping_method_categories, :created_at, false, current_time
    change_column_null :spree_shipping_method_categories, :updated_at, false, current_time
    change_column_null :spree_shipping_methods, :created_at, false, current_time
    change_column_null :spree_shipping_methods, :updated_at, false, current_time
    change_column_null :spree_shipping_rates, :created_at, false, current_time
    change_column_null :spree_shipping_rates, :updated_at, false, current_time
    change_column_null :spree_skrill_transactions, :created_at, false, current_time
    change_column_null :spree_skrill_transactions, :updated_at, false, current_time
    change_column_null :spree_state_changes, :created_at, false, current_time
    change_column_null :spree_state_changes, :updated_at, false, current_time
    change_column_null :spree_stock_items, :created_at, false, current_time
    change_column_null :spree_stock_items, :updated_at, false, current_time
    change_column_null :spree_stock_locations, :created_at, false, current_time
    change_column_null :spree_stock_locations, :updated_at, false, current_time
    change_column_null :spree_stock_movements, :created_at, false, current_time
    change_column_null :spree_stock_movements, :updated_at, false, current_time
    change_column_null :spree_stock_transfers, :created_at, false, current_time
    change_column_null :spree_stock_transfers, :updated_at, false, current_time
    change_column_null :spree_tax_categories, :created_at, false, current_time
    change_column_null :spree_tax_categories, :updated_at, false, current_time
    change_column_null :spree_tax_rates, :created_at, false, current_time
    change_column_null :spree_tax_rates, :updated_at, false, current_time
    change_column_null :spree_taxonomies, :created_at, false, current_time
    change_column_null :spree_taxonomies, :updated_at, false, current_time
    change_column_null :spree_taxons, :created_at, false, current_time
    change_column_null :spree_taxons, :updated_at, false, current_time
    change_column_null :spree_tokenized_permissions, :created_at, false, current_time
    change_column_null :spree_tokenized_permissions, :updated_at, false, current_time
    change_column_null :spree_users, :created_at, false, current_time
    change_column_null :spree_users, :updated_at, false, current_time
    change_column_null :spree_zone_members, :created_at, false, current_time
    change_column_null :spree_zone_members, :updated_at, false, current_time
    change_column_null :spree_zones, :created_at, false, current_time
    change_column_null :spree_zones, :updated_at, false, current_time
    change_column_null :stripe_accounts, :created_at, false, current_time
    change_column_null :stripe_accounts, :updated_at, false, current_time
    change_column_null :subscription_line_items, :created_at, false, current_time
    change_column_null :subscription_line_items, :updated_at, false, current_time
    change_column_null :subscriptions, :created_at, false, current_time
    change_column_null :subscriptions, :updated_at, false, current_time
    change_column_null :tag_rules, :created_at, false, current_time
    change_column_null :tag_rules, :updated_at, false, current_time
    change_column_null :column_preferences, :created_at, false, current_time
    change_column_null :column_preferences, :updated_at, false, current_time
  end

  def down
    change_column_null :customers, :created_at, true
    change_column_null :customers, :updated_at, true
    change_column_null :delayed_jobs, :created_at, true
    change_column_null :delayed_jobs, :updated_at, true
    change_column_null :distributors_shipping_methods, :created_at, true
    change_column_null :distributors_shipping_methods, :updated_at, true
    change_column_null :enterprise_fees, :created_at, true
    change_column_null :enterprise_fees, :updated_at, true
    change_column_null :enterprises, :created_at, true
    change_column_null :enterprises, :updated_at, true
    change_column_null :exchange_fees, :created_at, true
    change_column_null :exchange_fees, :updated_at, true
    change_column_null :exchange_variants, :created_at, true
    change_column_null :exchange_variants, :updated_at, true
    change_column_null :exchanges, :created_at, true
    change_column_null :exchanges, :updated_at, true
    change_column_null :inventory_items, :created_at, true
    change_column_null :inventory_items, :updated_at, true
    change_column_null :order_cycle_schedules, :created_at, true
    change_column_null :order_cycle_schedules, :updated_at, true
    change_column_null :order_cycles, :created_at, true
    change_column_null :order_cycles, :updated_at, true
    change_column_null :producer_properties, :created_at, true
    change_column_null :producer_properties, :updated_at, true
    change_column_null :proxy_orders, :created_at, true
    change_column_null :proxy_orders, :updated_at, true
    change_column_null :schedules, :created_at, true
    change_column_null :schedules, :updated_at, true
    change_column_null :sessions, :created_at, true
    change_column_null :sessions, :updated_at, true
    change_column_null :spree_activators, :created_at, true
    change_column_null :spree_activators, :updated_at, true
    change_column_null :spree_addresses, :created_at, true
    change_column_null :spree_addresses, :updated_at, true
    change_column_null :spree_adjustments, :created_at, true
    change_column_null :spree_adjustments, :updated_at, true
    change_column_null :spree_calculators, :created_at, true
    change_column_null :spree_calculators, :updated_at, true
    change_column_null :spree_configurations, :created_at, true
    change_column_null :spree_configurations, :updated_at, true
    change_column_null :spree_credit_cards, :created_at, true
    change_column_null :spree_credit_cards, :updated_at, true
    change_column_null :spree_gateways, :created_at, true
    change_column_null :spree_gateways, :updated_at, true
    change_column_null :spree_inventory_units, :created_at, true
    change_column_null :spree_inventory_units, :updated_at, true
    change_column_null :spree_line_items, :created_at, true
    change_column_null :spree_line_items, :updated_at, true
    change_column_null :spree_log_entries, :created_at, true
    change_column_null :spree_log_entries, :updated_at, true
    change_column_null :spree_option_types, :created_at, true
    change_column_null :spree_option_types, :updated_at, true
    change_column_null :spree_option_values, :created_at, true
    change_column_null :spree_option_values, :updated_at, true
    change_column_null :spree_orders, :created_at, true
    change_column_null :spree_orders, :updated_at, true
    change_column_null :spree_payment_methods, :created_at, true
    change_column_null :spree_payment_methods, :updated_at, true
    change_column_null :spree_payments, :created_at, true
    change_column_null :spree_payments, :updated_at, true
    change_column_null :spree_preferences, :created_at, true
    change_column_null :spree_preferences, :updated_at, true
    change_column_null :spree_product_option_types, :created_at, true
    change_column_null :spree_product_option_types, :updated_at, true
    change_column_null :spree_product_properties, :created_at, true
    change_column_null :spree_product_properties, :updated_at, true
    change_column_null :spree_products, :created_at, true
    change_column_null :spree_products, :updated_at, true
    change_column_null :spree_promotion_rules, :created_at, true
    change_column_null :spree_promotion_rules, :updated_at, true
    change_column_null :spree_properties, :created_at, true
    change_column_null :spree_properties, :updated_at, true
    change_column_null :spree_return_authorizations, :created_at, true
    change_column_null :spree_return_authorizations, :updated_at, true
    change_column_null :spree_shipments, :created_at, true
    change_column_null :spree_shipments, :updated_at, true
    change_column_null :spree_shipping_categories, :created_at, true
    change_column_null :spree_shipping_categories, :updated_at, true
    change_column_null :spree_shipping_method_categories, :created_at, true
    change_column_null :spree_shipping_method_categories, :updated_at, true
    change_column_null :spree_shipping_methods, :created_at, true
    change_column_null :spree_shipping_methods, :updated_at, true
    change_column_null :spree_shipping_rates, :created_at, true
    change_column_null :spree_shipping_rates, :updated_at, true
    change_column_null :spree_skrill_transactions, :created_at, true
    change_column_null :spree_skrill_transactions, :updated_at, true
    change_column_null :spree_state_changes, :created_at, true
    change_column_null :spree_state_changes, :updated_at, true
    change_column_null :spree_stock_items, :created_at, true
    change_column_null :spree_stock_items, :updated_at, true
    change_column_null :spree_stock_locations, :created_at, true
    change_column_null :spree_stock_locations, :updated_at, true
    change_column_null :spree_stock_movements, :created_at, true
    change_column_null :spree_stock_movements, :updated_at, true
    change_column_null :spree_stock_transfers, :created_at, true
    change_column_null :spree_stock_transfers, :updated_at, true
    change_column_null :spree_tax_categories, :created_at, true
    change_column_null :spree_tax_categories, :updated_at, true
    change_column_null :spree_tax_rates, :created_at, true
    change_column_null :spree_tax_rates, :updated_at, true
    change_column_null :spree_taxonomies, :created_at, true
    change_column_null :spree_taxonomies, :updated_at, true
    change_column_null :spree_taxons, :created_at, true
    change_column_null :spree_taxons, :updated_at, true
    change_column_null :spree_tokenized_permissions, :created_at, true
    change_column_null :spree_tokenized_permissions, :updated_at, true
    change_column_null :spree_users, :created_at, true
    change_column_null :spree_users, :updated_at, true
    change_column_null :spree_zone_members, :created_at, true
    change_column_null :spree_zone_members, :updated_at, true
    change_column_null :spree_zones, :created_at, true
    change_column_null :spree_zones, :updated_at, true
    change_column_null :stripe_accounts, :created_at, true
    change_column_null :stripe_accounts, :updated_at, true
    change_column_null :subscription_line_items, :created_at, true
    change_column_null :subscription_line_items, :updated_at, true
    change_column_null :subscriptions, :created_at, true
    change_column_null :subscriptions, :updated_at, true
    change_column_null :tag_rules, :created_at, true
    change_column_null :tag_rules, :updated_at, true
    change_column_null :column_preferences, :created_at, true
    change_column_null :column_preferences, :updated_at, true
  end
end
