# frozen_string_literal: true

# This file defines configurations that are universal to all spec types (feature, system, etc)

ENV["RAILS_ENV"] ||= 'test'

# for full configuration, see .simplecov
require 'simplecov' if ENV["COVERAGE"]

require 'pry' unless ENV['CI']
require 'view_component/test_helpers'

require_relative "../config/environment"
require 'rspec/rails'
require 'rspec/retry'
require 'capybara'
require 'paper_trail/frameworks/rspec'
require "factory_bot_rails"
require 'database_cleaner'

require 'shoulda/matchers'
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

require 'knapsack_pro'
KnapsackPro::Adapters::RSpecAdapter.bind

if ENV["COVERAGE"] && defined?(SimpleCov)
  KnapsackPro::Hooks::Queue.before_queue do
    SimpleCov.command_name("rspec_ci_node_#{KnapsackPro::Config::Env.ci_node_index}")
  end
end

# Allow connections to selenium whilst raising errors when connecting to external sites
require 'webmock/rspec'
WebMock.enable!
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: ['chromedriver.storage.googleapis.com']
)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Rails.root.glob("spec/support/**/*.rb").sort.each { |f| require f }

Capybara.server = :puma, { Silent: true }
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

# Disable timestamp check for test environment
InvisibleCaptcha.timestamp_enabled = false

InvisibleCaptcha.spinner_enabled = false

RSpec.configure do |config|
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

    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # We use too many mocks at the moment. Activating the following
    # feature fails a lot of specs. We should clean it up over time.
    #
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    # mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  # https://rspec.info/features/3-12/rspec-core/configuration/zero-monkey-patching-mode/
  config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  config.define_derived_metadata(file_path: %r{/spec/lib/tasks/}) do |metadata|
    metadata[:type] = :rake
  end

  # Reset locale for all specs.
  config.around(:each) do |example|
    locale = ENV.fetch('LOCALE', 'en_TST')
    I18n.with_locale(locale) { example.run }
  end

  # Fix encoding issue in Rails 5.0; allows passing empty arrays or hashes as params.
  config.before(:each, type: :controller) { @request.env["CONTENT_TYPE"] = 'application/json' }

  # Reset all feature toggles to prevent leaking.
  config.before(:each) do
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

  # Ensure we start with consistent config settings
  config.before(:each) do
    reset_spree_preferences do |spree_config|
      # These are all settings that differ from Spree's defaults
      spree_config.shipping_instructions = true
    end
    CurrentConfig.clear_all
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

  config.include_context "rake", type: :rake

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
  config.include OpenFoodNetwork::HtmlHelper
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ActionView::Helpers::DateHelper
  config.include OpenFoodNetwork::PerformanceHelper
  config.include ActiveJob::TestHelper
  config.include ReportsHelper
  config.include TomSelectHelper, type: :system

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
  config.include ProductsHelper, type: :system
end
