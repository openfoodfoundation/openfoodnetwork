# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<HIDDEN_KEY>') { ENV.fetch('STRIPE_SECRET_TEST_API_KEY', nil) }
  config.filter_sensitive_data('<HIDDEN_CUSTOMER>') { ENV.fetch('STRIPE_CUSTOMER', nil) }
  config.filter_sensitive_data('<HIDDEN_ACCOUNT>') { ENV.fetch('STRIPE_ACCOUNT', nil) }
  config.ignore_hosts('localhost', '127.0.0.1', '0.0.0.0', 'api.knapsackpro.com')
end
