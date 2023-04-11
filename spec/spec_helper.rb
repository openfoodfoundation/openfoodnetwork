# frozen_string_literal: true

require 'base_spec_helper'
require 'database_cleaner'

RSpec.configure do |config|
  # DatabaseCleaner
  config.before(:each, concurrency: true) do
    config.use_transactional_fixtures = false
    DatabaseCleaner.strategy = :deletion, { except: ['spree_countries', 'spree_states'] }
    DatabaseCleaner.start
  end
  config.after(:each, concurrency: true) do
    DatabaseCleaner.clean
    config.use_transactional_fixtures = true
  end

  # Precompile Webpacker assets (once) when starting the suite. The default setup can result
  # in the assets getting compiled many times throughout the build, slowing it down.
  config.before :suite do
    Webpacker.compile
  end

  # Fix encoding issue in Rails 5.0; allows passing empty arrays or hashes as params.
  config.before(:each, type: :controller) { @request.env["CONTENT_TYPE"] = 'application/json' }

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can use `rspec -n` to run only failed specs.
  config.example_status_persistence_file_path = "tmp/rspec-status.txt"
end
