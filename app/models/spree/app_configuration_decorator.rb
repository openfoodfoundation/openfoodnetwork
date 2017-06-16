Spree::AppConfiguration.class_eval do
  # This file decorates the existing preferences file defined by Spree.
  # It allows us to add our own global configuration variables, which
  # we can allow to be modified in the UI by adding appropriate form
  # elements to existing or new configuration pages.

  # Embedded Shopfronts
  preference :enable_embedded_shopfronts, :boolean, default: false
  preference :embedded_shopfronts_whitelist, :text, default: nil

  # Terms of Service Preferences
  preference :enterprises_require_tos, :boolean, default: false

  # Tax Preferences
  preference :products_require_tax_category, :boolean, default: false
  preference :shipping_tax_rate, :decimal, default: 0

  # Accounts & Billing Preferences
  preference :accounts_distributor_id, :integer, default: nil
  preference :default_accounts_payment_method_id, :integer, default: nil
  preference :default_accounts_shipping_method_id, :integer, default: nil
  preference :auto_update_invoices, :boolean, default: false
  preference :auto_finalize_invoices, :boolean, default: false

  # Business Model Configuration
  preference :account_invoices_monthly_fixed, :decimal, default: 0
  preference :account_invoices_monthly_rate, :decimal, default: 0
  preference :account_invoices_monthly_cap, :decimal, default: 0
  preference :account_invoices_tax_rate, :decimal, default: 0
  preference :shop_trial_length_days, :integer, default: 30
  preference :minimum_billable_turnover, :integer, default: 0

  # Monitoring
  preference :last_job_queue_heartbeat_at, :string, default: nil

  # External services
  preference :bugherd_api_key, :string, default: nil

  # Invoices & Receipts
  preference :invoice_style2?, :boolean, default: false
  preference :enable_receipt_printing?, :boolean, default: false

  # Stripe Connect
  preference :stripe_connect_enabled, :boolean, default: false
end
