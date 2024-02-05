# frozen_string_literal: true

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
  Stripe.api_key = if Rails.env.test? || ENV["CI"]
                     ENV.fetch('STRIPE_SECRET_TEST_API_KEY', nil)
                   else
                     ENV.fetch('STRIPE_INSTANCE_SECRET_KEY', nil)
                   end

  Stripe.publishable_key = ENV.fetch('STRIPE_INSTANCE_PUBLISHABLE_KEY', nil)
  Stripe.client_id = ENV.fetch('STRIPE_CLIENT_ID', nil)
  Stripe.endpoint_secret = ENV.fetch('STRIPE_ENDPOINT_SECRET', nil)
end
