# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.configure_rspec_metadata!
  config.ignore_hosts('localhost', '127.0.0.1', '0.0.0.0', 'api.knapsackpro.com')

  # Filter sensitive environment variables
  [
    'STRIPE_SECRET_TEST_API_KEY',
    'STRIPE_CUSTOMER',
    'STRIPE_ACCOUNT',
    'STRIPE_CLIENT_ID',
  ].each do |env_var|
    config.filter_sensitive_data("<HIDDEN-#{env_var}>") { ENV.fetch(env_var, nil) }
  end
end
