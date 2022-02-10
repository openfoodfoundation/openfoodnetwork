# Add some additional properties, to allow us to access these
# properties from the object, rather than calling from ENV directly.
# This is mostly useful for stubbing when testing, but also feels
# a bit cleaner than accessing keys in different ways.
module Stripe
  class << self
    # Returns the value of Stripe.publishable_key and Stripe.endpoint_secret.
    # Attribute values can also be set by doing Stripe.publishable_key = <your_new_value>
    attr_accessor :publishable_key, :endpoint_secret
  end
end

Rails.application.reloader.to_prepare do
  Stripe.api_key = ENV['STRIPE_INSTANCE_SECRET_KEY']
  Stripe.publishable_key = ENV['STRIPE_INSTANCE_PUBLISHABLE_KEY']
  Stripe.client_id = ENV['STRIPE_CLIENT_ID']
  Stripe.endpoint_secret = ENV['STRIPE_ENDPOINT_SECRET']
end