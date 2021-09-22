class MigratePinPaymentToCash < ActiveRecord::Migration[6.1]
  def change
    execute "UPDATE spree_payment_methods SET type = 'Spree::PaymentMethod::Check' WHERE type = 'Spree::Gateway::Pin'"
  end
end
