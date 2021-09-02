# frozen_string_literal: true

require 'base_spec_helper'

require 'database_cleaner'
require 'webdrivers'
require 'selenium-webdriver'
require 'view_component/test_helpers'

# This spec_helper.rb is being used by the custom engines in engines/. The engines are not set up to
# use Knapsack, and this provides the option to disable it when running the tests in CI services.
unless ENV['DISABLE_KNAPSACK']
  require 'knapsack'
  Knapsack.tracker.config(enable_time_offset_warning: false) unless ENV['CI']
  Knapsack::Adapters::RSpecAdapter.bind
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[headless disable-gpu no-sandbox window-size=1280,768]
  )
  options.add_preference(:download, default_directory: DownloadsHelper.path.to_s)

  Capybara::Selenium::Driver
    .new(app, browser: :chrome, options: options)
    .tap { |driver| driver.browser.download_path = DownloadsHelper.path.to_s }
end

Capybara.javascript_driver = :chrome
Capybara.default_max_wait_time = 30

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

  def restart_driver
    Capybara.send('session_pool').values
      .select { |s| s.driver.is_a?(Capybara::Selenium::Driver) }
      .each { |s| s.driver.reset! }
  end
  config.before(:all) { restart_driver }

  config.after(:each, js: true) do
    Capybara.reset_sessions!
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
  # results = []
  # config.before(:each) do |expectation|
  #   expectation_identifier = [expectation.id, expectation.description] 
  #   results << expectation_identifier
  # end
  # config.after(:suite) do |_nothing|
  #   puts "***RESULTS BEGIN***"
  #   results.each do |result|
  #     puts "#{result}*****"
  #   end
  #   puts "***RESULTS END***"
  # end
end
