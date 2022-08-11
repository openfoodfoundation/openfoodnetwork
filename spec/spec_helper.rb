# frozen_string_literal: true

require 'base_spec_helper'

require 'database_cleaner'
require 'view_component/test_helpers'

# This spec_helper.rb is being used by the custom engines in engines/. The engines are not set up to
# use Knapsack, and this provides the option to disable it when running the tests in CI services.
unless ENV['DISABLE_KNAPSACK']
  require 'knapsack'
  Knapsack.tracker.config(enable_time_offset_warning: false) unless ENV['CI']
  Knapsack::Adapters::RSpecAdapter.bind
end

Capybara.javascript_driver = :chrome
Capybara.default_max_wait_time = 30
Capybara.disable_animation = true

RSpec.configure do |config|
  # DatabaseCleaner
  config.before(:suite) {
    DatabaseCleaner.clean_with :deletion, except: ['spree_countries', 'spree_states']
  }
  config.before(:each)           { DatabaseCleaner.strategy = :transaction }
  config.before(:each, js: true) {
    DatabaseCleaner.strategy = :deletion, { except: ['spree_countries', 'spree_states'] }
  }
  config.before(:each, concurrency: true) {
    DatabaseCleaner.strategy = :deletion, { except: ['spree_countries', 'spree_states'] }
  }
  config.before(:each)           { DatabaseCleaner.start }
  config.after(:each)            { DatabaseCleaner.clean }

  config.after(:each, js: true) do
    Capybara.reset_sessions!
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
  config.use_transactional_fixtures = false

  # Helpers
  config.include ViewComponent::TestHelpers, type: :component
  config.include ControllerRequestsHelper, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include OpenFoodNetwork::ApiHelper, type: :controller
  config.include OpenFoodNetwork::ControllerHelper, type: :controller
  config.include Features::DatepickerHelper, type: :feature
  config.include DownloadsHelper, type: :feature
end
