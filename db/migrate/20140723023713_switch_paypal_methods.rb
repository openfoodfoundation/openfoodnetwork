class SwitchPaypalMethods < ActiveRecord::Migration
  def up
    Spree::PaymentMethod.connection.execute <<EOS
UPDATE spree_payment_methods
SET type='Spree::Gateway::PayPalExpress'
WHERE type IN ('Spree::BillingIntegration::PaypalExpress', 'Spree::BillingIntegration::PaypalExpressUk')
EOS
  end

  def down
    Spree::PaymentMethod.connection.execute "UPDATE spree_payment_methods SET type='Spree::BillingIntegration::PaypalExpress' WHERE type='Spree::Gateway::PayPalExpress'"
  end
end
