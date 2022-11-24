# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<HIDDEN_KEY>') { ENV['STRIPE_SECRET_TEST_API_KEY'] }
  config.filter_sensitive_data('<HIDDEN_CUSTOMER>') { ENV['STRIPE_CUSTOMER'] }
  config.ignore_hosts('localhost', '127.0.0.1', '0.0.0.0', 'api.knapsackpro.com')
end
