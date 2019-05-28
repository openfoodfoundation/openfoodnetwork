require 'spree/concerns/payment_method_distributors'

Spree::Gateway.class_eval do
  include Spree::PaymentMethodDistributors

  # Default to live
  preference :server, :string, default: 'live'
  preference :test_mode, :boolean, default: false
end
