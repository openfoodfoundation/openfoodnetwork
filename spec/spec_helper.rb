# frozen_string_literal: true

require 'base_spec_helper'
require 'database_cleaner'

RSpec.configure do |config|
  # Precompile Webpacker assets (once) when starting the suite. The default setup can result
  # in the assets getting compiled many times throughout the build, slowing it down.
  config.before :suite do
    Webpacker.compile
  end

  # Fix encoding issue in Rails 5.0; allows passing empty arrays or hashes as params.
  config.before(:each, type: :controller) { @request.env["CONTENT_TYPE"] = 'application/json' }

  # Setting this to true keeps the database clean by rolling back any changes.
  config.use_transactional_fixtures = true

  # Some tests don't work within a transaction. Then we use DatabaseCleaner.
  config.before(:each, concurrency: true) do
    config.use_transactional_fixtures = false
    DatabaseCleaner.strategy = :deletion, { except: ['spree_countries', 'spree_states'] }
    DatabaseCleaner.start
  end
  config.append_after(:each, concurrency: true) do
    DatabaseCleaner.clean
    config.use_transactional_fixtures = true
  end
end
