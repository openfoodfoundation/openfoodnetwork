class AddShippingFeeEstimateAndPaymentFeeEstimateToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :shipping_fee_estimate, :decimal, :precision => 8,  :scale => 2
    add_column :subscriptions, :payment_fee_estimate, :decimal, :precision => 8,  :scale => 2
  end
end
