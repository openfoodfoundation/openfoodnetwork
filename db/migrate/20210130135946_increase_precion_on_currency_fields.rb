class IncreasePrecionOnCurrencyFields < ActiveRecord::Migration[4.2]
  def up
    change_column :spree_line_items, :price, :decimal, precision: 10, scale: 2
    change_column :spree_line_items, :cost_price, :decimal, precision: 10, scale: 2
    change_column :spree_prices, :amount, :decimal, precision: 10, scale: 2
    change_column :spree_shipments, :cost, :decimal, precision: 10, scale: 2
    change_column :spree_shipping_rates, :cost, :decimal, precision: 10, scale: 2
    change_column :spree_variants, :cost_price, :decimal, precision: 10, scale: 2
    change_column :subscription_line_items, :price_estimate, :decimal, precision: 10, scale: 2
    change_column :subscriptions, :shipping_fee_estimate, :decimal, precision: 10, scale: 2
    change_column :subscriptions, :payment_fee_estimate, :decimal, precision: 10, scale: 2
    change_column :variant_overrides, :price, :decimal, precision: 10, scale: 2
  end

  def down
    change_column :spree_line_items, :price, :decimal, precision: 8, scale: 2
    change_column :spree_line_items, :cost_price, :decimal, precision: 8, scale: 2
    change_column :spree_prices, :amount, :decimal, precision: 8, scale: 2
    change_column :spree_shipments, :cost, :decimal, precision: 8, scale: 2
    change_column :spree_shipping_rates, :cost, :decimal, precision: 8, scale: 2
    change_column :spree_variants, :cost_price, :decimal, precision: 8, scale: 2
    change_column :subscription_line_items, :price_estimate, :decimal, precision: 8, scale: 2
    change_column :subscriptions, :shipping_fee_estimate, :decimal, precision: 8, scale: 2
    change_column :subscriptions, :payment_fee_estimate, :decimal, precision: 8, scale: 2
    change_column :variant_overrides, :price, :decimal, precision: 8, scale: 2
  end
end
