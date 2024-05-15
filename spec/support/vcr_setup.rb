# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.configure_rspec_metadata!
  config.ignore_localhost = true

  # Filter sensitive environment variables
  %w[
    STRIPE_INSTANCE_SECRET_KEY
    STRIPE_CUSTOMER
    STRIPE_ACCOUNT
    STRIPE_CLIENT_ID
    STRIPE_ENDPOINT_SECRET
    OPENID_APP_ID
    OPENID_APP_SECRET
    OPENID_REFRESH_TOKEN
  ].each do |env_var|
    config.filter_sensitive_data("<HIDDEN-#{env_var}>") { ENV.fetch(env_var, nil) }
  end
  config.filter_sensitive_data('<HIDDEN-STRIPE-USER-AGENT>') { |interaction|
    interaction.request.headers['X-Stripe-Client-User-Agent']&.public_send(:[], 0)
  }
  config.filter_sensitive_data('<HIDDEN-CLIENT-SECRET>') { |interaction|
    interaction.response.body.match(/"client_secret": "(pi_.+)"/)&.public_send(:[], 1)
  }
  config.filter_sensitive_data('<HIDDEN-AUTHORIZATION-HEADER>') { |interaction|
    interaction.request.headers['Authorization']&.public_send(:[], 0)
  }
  config.filter_sensitive_data('<HIDDEN-OPENID-TOKEN>') { |interaction|
    interaction.response.body.match(/"access_token":"([^"]+)"/)&.public_send(:[], 1)
  }
  config.filter_sensitive_data('<HIDDEN-OPENID-TOKEN>') { |interaction|
    interaction.response.body.match(/"id_token":"([^"]+)"/)&.public_send(:[], 1)
  }
  config.filter_sensitive_data('<HIDDEN-OPENID-TOKEN>') { |interaction|
    interaction.response.body.match(/"refresh_token":"([^"]+)"/)&.public_send(:[], 1)
  }
end
