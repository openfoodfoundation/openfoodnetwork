# This migration comes from spree_paypal_express (originally 20140117051315)
class RenamePaymentMethods < ActiveRecord::Migration
  def up
    execute <<-SQL
      update spree_payment_methods set type = 'Spree::Gateway::PayPalExpress' WHERE type = 'Spree::BillingIntegration::PaypalExpress'
    SQL
  end

  def down
    execute <<-SQL
      update spree_payment_methods set type = 'Spree::BillingIntegration::PaypalExpress' WHERE type = 'Spree::Gateway::PayPalExpress'
    SQL
  end
end
