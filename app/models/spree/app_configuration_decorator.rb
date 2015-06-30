Spree::AppConfiguration.class_eval do
  # This file decorates the existing preferences file defined by Spree.
  # It allows us to add our own global configuration variables, which
  # we can allow to be modified in the UI by adding appropriate form
  # elements to existing or new configuration pages.

  # Tax Preferences
  preference :products_require_tax_category, :boolean, default: false
  preference :shipping_tax_rate, :decimal, default: 0

  # Accounts & Billing Preferences
  preference :accounts_distributor_id, :integer, default: nil
  preference :collect_billing_information, :boolean, default: false
  preference :create_invoices_for_enterprise_users, :boolean, default: false
end
