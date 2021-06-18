# frozen_string_literal: true

require 'simplecov' if ENV["COVERAGE"]

require 'rubygems'

# Require pry when we're not inside Travis-CI
require 'pry' unless ENV['CI']

# This spec_helper.rb is being used by the custom engines in engines/. The engines are not set up to
# use Knapsack, and this provides the option to disable it when running the tests in CI services.
unless ENV['DISABLE_KNAPSACK']
  require 'knapsack'
  Knapsack.tracker.config(enable_time_offset_warning: false) unless ENV['CI']
  Knapsack::Adapters::RSpecAdapter.bind
end

ENV["RAILS_ENV"] ||= 'test'
require_relative "../config/environment"
require 'rspec/rails'
require 'capybara'
require 'database_cleaner'
require 'rspec/retry'
require 'paper_trail/frameworks/rspec'

require 'webdrivers'

require 'shoulda/matchers'
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Allow connections to selenium whilst raising errors when connecting to external sites
require 'webmock/rspec'
WebMock.enable!
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: 'chromedriver.storage.googleapis.com'
)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }
require 'support/api_helper'

# Capybara config
require 'selenium-webdriver'
Capybara.javascript_driver = :chrome
Capybara.server = :webrick

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[headless disable-gpu no-sandbox window-size=1280,768]
  )
  options.add_preference(:download, default_directory: DownloadsHelper.path.to_s)

  Capybara::Selenium::Driver
    .new(app, browser: :chrome, options: options)
    .tap { |driver| driver.browser.download_path = DownloadsHelper.path.to_s }
end

Capybara.default_max_wait_time = 30

Capybara.configure do |config|
  config.match = :prefer_exact
  config.ignore_hidden_elements = true
end

require "paperclip/matchers"

# Override setting in Spree engine: Spree::Core::MailSettings
ActionMailer::Base.default_url_options[:host] = 'test.host'

require "view_component/test_helpers"

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Show retries in test output
  config.verbose_retry = true
  # Set maximum retry count
  config.default_retry_count = 1

  # Force colored output, whether or not the output is a TTY
  config.color_mode = :on

  # Force use of expect (over should)
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

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

  def restart_driver
    Capybara.send('session_pool').values
      .select { |s| s.driver.is_a?(Capybara::Selenium::Driver) }
      .each { |s| s.driver.reset! }
  end
  config.before(:all) { restart_driver }

  # Enable caching in any specs tagged with `caching: true`. Usage is exactly the same as the
  # well-known `js: true` tag used to enable javascript in feature specs.
  config.around(:each, :caching) do |example|
    caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = example.metadata[:caching]
    example.run
    ActionController::Base.perform_caching = caching
  end

  # Fix encoding issue in Rails 5.0; allows passing empty arrays or hashes as params.
  config.before(:each, type: :controller) { @request.env["CONTENT_TYPE"] = 'application/json' }

  # Show javascript errors in test output with `js_debug: true`
  config.after(:each, :js_debug) do
    errors = page.driver.browser.manage.logs.get(:browser)
    if errors.present?
      message = errors.map(&:message).join("\n")
      puts message
    end
  end

  # Webmock raises errors that inherit directly from Exception (not StandardError).
  # The messages contain useful information for debugging stubbed requests to external
  # services (in tests), but they normally don't appear in the test output.
  config.before(:all) do
    ApplicationController.class_eval do
      rescue_from WebMock::NetConnectNotAllowedError, with: :handle_webmock_error

      def handle_webmock_error(exception)
        raise exception.message
      end
    end
  end

  # Geocoding
  config.before(:each) {
    allow_any_instance_of(Spree::Address).to receive(:geocode).and_return([1, 1])
  }

  default_country_id = DefaultCountry.id
  checkout_zone = Spree::Config[:checkout_zone]
  currency = Spree::Config[:currency]
  # Ensure we start with consistent config settings
  config.before(:each) do
    reset_spree_preferences do |spree_config|
      # These are all settings that differ from Spree's defaults
      spree_config.default_country_id = default_country_id
      spree_config.checkout_zone = checkout_zone
      spree_config.currency = currency
      spree_config.shipping_instructions = true
    end
  end

  # Helpers
  config.include Rails.application.routes.url_helpers
  config.include Spree::UrlHelpers
  config.include Spree::MoneyHelper
  config.include PreferencesHelper
  config.include ControllerRequestsHelper, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include OpenFoodNetwork::ApiHelper, type: :controller
  config.include OpenFoodNetwork::ControllerHelper, type: :controller
  config.include Features::DatepickerHelper, type: :feature
  config.include OpenFoodNetwork::FeatureToggleHelper
  config.include OpenFoodNetwork::FiltersHelper
  config.include OpenFoodNetwork::EnterpriseGroupsHelper
  config.include OpenFoodNetwork::ProductsHelper
  config.include OpenFoodNetwork::DistributionHelper
  config.include OpenFoodNetwork::HtmlHelper
  config.include ActionView::Helpers::DateHelper
  config.include OpenFoodNetwork::PerformanceHelper
  config.include DownloadsHelper, type: :feature
  config.include ActiveJob::TestHelper

  # FactoryBot
  require 'factory_bot_rails'
  config.include FactoryBot::Syntax::Methods

  config.include Paperclip::Shoulda::Matchers

  config.include JsonSpec::Helpers

  # Profiling
  #
  # This code shouldn't be run in normal circumstances. But if you want to know
  # which parts of your code take most time, then you can activate the lines
  # below. Keep in mind that it will slow down the execution time heaps.
  #
  # The PerfTools will write a binary file to the specified path which can then
  # be examined by:
  #
  #   bundle exec pprof.rb --text  /tmp/rspec_profile
  #

  # require 'perftools'
  # config.before :suite do
  #  PerfTools::CpuProfiler.start("/tmp/rspec_profile")
  # end
  #
  # config.after :suite do
  # PerfTools::CpuProfiler.stop
  # end
  config.infer_spec_type_from_file_location!

  config.include ViewComponent::TestHelpers, type: :component
end

FactoryBot.use_parent_strategy = false
