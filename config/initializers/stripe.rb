# Add the :publishable_key property, to allow us to access this
# property from the object, rather than calling from ENV directly.
# This is mostly useful for stubbing when testing, but also feels
# a bit cleaner than accessing keys in different ways.
module Stripe
  class << self
    attr_accessor :publishable_key
  end
end

Stripe.api_key = ENV['STRIPE_INSTANCE_SECRET_KEY']
Stripe.publishable_key = ENV['STRIPE_INSTANCE_PUBLISHABLE_KEY']
Stripe.client_id = ENV['STRIPE_CLIENT_ID']
