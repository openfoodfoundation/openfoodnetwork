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

FactoryBot.use_parent_strategy = false
FactoryBot::SyntaxRunner.include FileHelper

# raise I18n exception handler
I18n.exception_handler = proc do |exception, *_|
  raise exception.to_exception
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{Rails.root.join('spec/fixtures')}"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  #
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

  # Reset all feature toggles to prevent leaking.
  config.before(:suite) do
    Flipper.features.each(&:remove)
    OpenFoodNetwork::FeatureToggle.setup!
  end

  config.before(:each, :feature) do |example|
    feature = example.metadata[:feature].to_s

    unless OpenFoodNetwork::FeatureToggle::CURRENT_FEATURES.key?(feature)
      raise "Unkown feature: #{feature}"
    end

    Flipper.enable(feature)
  end

  # Enable caching in any specs tagged with `caching: true`.
  config.around(:each, :caching) do |example|
    caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = example.metadata[:caching]
    example.run
    ActionController::Base.perform_caching = caching
  end

  # Take example responses from Rswag specs for API documentation.
  # https://github.com/rswag/rswag#enable-auto-generation-examples-from-responses
  config.after(:each, :rswag_autodoc) do |example|
    # Categories and group operations of the same API endpoint.
    example.metadata[:operation][:tags] ||= [self.class.top_level_description]

    next if response&.body.blank?

    # Include response as example in the documentation.
    example.metadata[:response][:content] ||= {}
    example.metadata[:response][:content].deep_merge!(
      {
        "application/json" => {
          examples: {
            test_example: {
              value: JSON.parse(response.body, symbolize_names: true)
            }
          }
        }
      }
    )
  end

  # Show javascript errors in test output with `js_debug: true`
  config.after(:each, :js_debug) do
    errors = page.driver.browser.manage.logs.get(:browser)
    if errors.present?
      message = errors.map(&:message).join("\n")
      puts message
    end
  end

  # Appends Stripe gem version to VCR cassette directory with ':stripe_version' flag
  #
  # When the Stripe gem is updated, we should re-record these cassettes:
  #
  #     ./script/test-stripe-live
  #
  config.around(:each, :stripe_version) do |example|
    stripe_version = "Stripe-v#{Stripe::VERSION}"
    cassette_library_dir, default_cassette_options = nil, nil

    VCR.configure do |vcr_config|
      cassette_library_dir = vcr_config.cassette_library_dir
      default_cassette_options = vcr_config.default_cassette_options
      vcr_config.cassette_library_dir += "/#{stripe_version}"
      vcr_config.default_cassette_options = { record: :none } if ENV["CI"]
    end

    example.run

    VCR.configure do |vcr_config|
      vcr_config.cassette_library_dir = cassette_library_dir
      vcr_config.default_cassette_options = default_cassette_options
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

  # Don't validate our invalid test data with expensive network requests.
  config.before(:each) do
    allow_any_instance_of(ValidEmail2::Address).to receive_messages(
      valid_mx?: true,
      valid_strict_mx?: true,
      mx_server_is_in?: false
    )
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

  # You can use `rspec -n` to run only failed specs.
  config.example_status_persistence_file_path = "tmp/rspec-status.txt"

  # Helpers
  config.include FactoryBot::Syntax::Methods
  config.include JsonSpec::Helpers

  config.include Rails.application.routes.url_helpers
  config.include Spree::UrlHelpers
  config.include Spree::MoneyHelper
  config.include Spree::PaymentHelper
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

  config.include ViewComponent::TestHelpers, type: :component

  config.include ControllerRequestsHelper, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include OpenFoodNetwork::ApiHelper, type: :controller
  config.include OpenFoodNetwork::ControllerHelper, type: :controller

  config.include Devise::Test::IntegrationHelpers, type: :request

  config.include Features::DatepickerHelper, type: :system
  config.include Features::TrixEditorHelper, type: :system
  config.include DownloadsHelper, type: :system
  config.include ReportsHelper, type: :system
end
