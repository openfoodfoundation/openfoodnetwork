# frozen_string_literal: true

# This file defines configurations that are universal to all spec types (feature, system, etc)

ENV["RAILS_ENV"] ||= 'test'

require 'simplecov' if ENV["COVERAGE"]
require 'rubygems'
require 'pry' unless ENV['CI']
require 'view_component/test_helpers'

require_relative "../config/environment"
require 'rspec/rails'
require 'rspec/retry'
require 'capybara'
require 'paper_trail/frameworks/rspec'
require "factory_bot_rails"

require 'shoulda/matchers'
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

require 'knapsack_pro'
KnapsackPro::Adapters::RSpecAdapter.bind

# Allow connections to selenium whilst raising errors when connecting to external sites
require 'webmock/rspec'
WebMock.enable!
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: ['chromedriver.storage.googleapis.com', 'api.knapsackpro.com']
)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

Capybara.server = :puma
Capybara.disable_animation = true

Capybara.configure do |config|
  config.match = :prefer_exact
  config.ignore_hidden_elements = true
end

# Override setting in Spree engine: Spree::Core::MailSettings
ActionMailer::Base.default_url_options[:host] = ENV["SITE_URL"]

FactoryBot.use_parent_strategy = false
FactoryBot::SyntaxRunner.include FileHelper

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Show retries in test output
  config.verbose_retry = true

  # Force colored output, whether or not the output is a TTY
  config.color_mode = :on

  # Force use of expect (over should)
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  # Enable caching in any specs tagged with `caching: true`.
  config.around(:each, :caching) do |example|
    caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = example.metadata[:caching]
    example.run
    ActionController::Base.perform_caching = caching
  end

  # Show javascript errors in test output with `js_debug: true`
  config.after(:each, :js_debug) do
    errors = page.driver.browser.manage.logs.get(:browser)
    if errors.present?
      message = errors.map(&:message).join("\n")
      puts message
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

  config.infer_spec_type_from_file_location!

  config.include FactoryBot::Syntax::Methods
  config.include JsonSpec::Helpers

  config.include Rails.application.routes.url_helpers
  config.include Spree::UrlHelpers
  config.include Spree::MoneyHelper
  config.include PreferencesHelper
  config.include OpenFoodNetwork::FiltersHelper
  config.include OpenFoodNetwork::EnterpriseGroupsHelper
  config.include OpenFoodNetwork::ProductsHelper
  config.include OpenFoodNetwork::DistributionHelper
  config.include OpenFoodNetwork::HtmlHelper
  config.include ActionView::Helpers::DateHelper
  config.include OpenFoodNetwork::PerformanceHelper
  config.include ActiveJob::TestHelper
  config.include ReportsHelper

  config.include Features::DatepickerHelper, type: :system
  config.include DownloadsHelper, type: :system
end
