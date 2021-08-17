class RenameStripeConnectPaymentMethodsToStripeSca < ActiveRecord::Migration[6.1]
  def change
    execute "UPDATE spree_payment_methods SET type = 'Spree::Gateway::StripeSCA' WHERE type = 'Spree::Gateway::StripeConnect'"
  end
end
