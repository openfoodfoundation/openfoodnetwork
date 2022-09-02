ENV["RAILS_ENV"] ||= 'test'

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.default_cassette_options = { record: :once }
  config.ignore_localhost = true
  config.configure_rspec_metadata!
end
