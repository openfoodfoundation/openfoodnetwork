class UpdateMigsGatewayToCheck < ActiveRecord::Migration[6.1]
  def change
    execute "UPDATE spree_payment_methods SET type = 'Spree::PaymentMethod::Check' WHERE type = 'Spree::Gateway::Migs'"
  end
end
