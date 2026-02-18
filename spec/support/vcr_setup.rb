# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Change recording mode during development:
  #
  #   VCR_RECORD=new_episodes ./bin/rspec spec/example_spec.rb
  #   VCR_RECORD=all          ./bin/rspec spec/example_spec.rb
  #
  if ENV.fetch("VCR_RECORD", nil)
    config.default_cassette_options = { record: ENV.fetch("VCR_RECORD").to_sym }
  end

  # Chrome calls a lot of services and they trip us up.
  config.ignore_hosts(
    "localhost", "127.0.0.1", "0.0.0.0",
    "accounts.google.com",
    "android.clients.google.com",
    "clients2.google.com",
    "content-autofill.googleapis.com",
    "optimizationguide-pa.googleapis.com",
  )

  # Filter sensitive environment variables
  %w[
    BUGSNAG_API_KEY
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

  # FDC specific parameter:
  config.filter_sensitive_data('<HIDDEN-OPENID-TOKEN>') { |interaction|
    interaction.request.body.match(/"accessToken":"([^"]+)"/)&.public_send(:[], 1)
  }
  config.filter_sensitive_data('<HIDDEN-VINE-TOKEN>') { |interaction|
    interaction.request.headers["X-Authorization"]&.public_send(:[], 0)
  }
end
