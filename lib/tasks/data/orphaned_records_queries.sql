SELECT COUNT(*) FROM spree_stock_movements LEFT JOIN spree_stock_items ON spree_stock_movements.stock_item_id = spree_stock_items.id WHERE spree_stock_items.id IS NULL

SELECT COUNT(*) FROM spree_stock_locations LEFT JOIN spree_states ON spree_stock_locations.state_id = spree_states.id WHERE spree_states.id IS NULL

SELECT COUNT(*) FROM spree_stock_locations LEFT JOIN spree_countries ON spree_stock_locations.country_id = spree_countries.id WHERE spree_countries.id IS NULL

SELECT COUNT(*) FROM spree_stock_items LEFT JOIN spree_stock_locations ON spree_stock_items.stock_location_id = spree_stock_locations.id WHERE spree_stock_locations.id IS NULL

SELECT COUNT(*) FROM spree_stock_items LEFT JOIN spree_variants ON spree_stock_items.variant_id = spree_variants.id WHERE spree_variants.id IS NULL

SELECT COUNT(*) FROM spree_shipping_rates LEFT JOIN spree_shipments ON spree_shipping_rates.shipment_id = spree_shipments.id WHERE spree_shipments.id IS NULL

SELECT COUNT(*) FROM spree_shipping_rates LEFT JOIN spree_shipping_methods ON spree_shipping_rates.shipping_method_id = spree_shipping_methods.id WHERE spree_shipping_methods.id IS NULL

SELECT COUNT(*) FROM spree_shipping_method_categories LEFT JOIN spree_shipping_methods ON spree_shipping_method_categories.shipping_method_id = spree_shipping_methods.id WHERE spree_shipping_methods.id IS NULL

SELECT COUNT(*) FROM spree_shipping_method_categories LEFT JOIN spree_shipping_categories ON spree_shipping_method_categories.shipping_category_id = spree_shipping_categories.id WHERE spree_shipping_categories.id IS NULL

SELECT COUNT(*) FROM spree_shipping_methods LEFT JOIN spree_tax_categories ON spree_shipping_methods.tax_category_id = spree_tax_categories.id WHERE spree_tax_categories.id IS NULL

SELECT COUNT(*) FROM spree_shipments LEFT JOIN spree_stock_locations ON spree_shipments.stock_location_id = spree_stock_locations.id WHERE spree_stock_locations.id IS NULL

SELECT COUNT(*) FROM spree_line_items LEFT JOIN spree_tax_categories ON spree_line_items.tax_category_id = spree_tax_categories.id WHERE spree_tax_categories.id IS NULL

SELECT COUNT(*) FROM spree_credit_cards LEFT JOIN spree_payment_methods ON spree_credit_cards.payment_method_id = spree_payment_methods.id WHERE spree_payment_methods.id IS NULL

SELECT COUNT(*) FROM spree_credit_cards LEFT JOIN spree_users ON spree_credit_cards.user_id = spree_users.id WHERE spree_users.id IS NULL

SELECT COUNT(*) FROM spree_adjustments LEFT JOIN spree_orders ON spree_adjustments.order_id = spree_orders.id WHERE spree_orders.id IS NULL

SELECT COUNT(*) FROM spree_adjustments LEFT JOIN spree_tax_categories ON spree_adjustments.tax_category_id = spree_tax_categories.id WHERE spree_tax_categories.id IS NULL

SELECT COUNT(*) FROM tag_rules LEFT JOIN enterprises ON tag_rules.enterprise_id = enterprises.id WHERE enterprises.id IS NULL

SELECT COUNT(*) FROM stripe_accounts LEFT JOIN enterprises ON stripe_accounts.enterprise_id = enterprises.id WHERE enterprises.id IS NULL

SELECT COUNT(*) FROM report_rendering_options LEFT JOIN spree_users ON report_rendering_options.user_id = spree_users.id WHERE spree_users.id IS NULL

SELECT COUNT(*) FROM inventory_items LEFT JOIN enterprises ON inventory_items.enterprise_id = enterprises.id WHERE enterprises.id IS NULL

SELECT COUNT(*) FROM inventory_items LEFT JOIN spree_variants ON inventory_items.variant_id = spree_variants.id WHERE spree_variants.id IS NULL

SELECT COUNT(*) FROM column_preferences LEFT JOIN spree_users ON column_preferences.user_id = spree_users.id WHERE spree_users.id IS NULL
