require 'rubygems'

# Require pry when we're not inside Travis-CI
require 'pry' unless ENV['CI']

require 'knapsack'
Knapsack.tracker.config({enable_time_offset_warning: false}) unless ENV['CI']
Knapsack::Adapters::RSpecAdapter.bind

ENV["RAILS_ENV"] ||= 'test'
require_relative "../config/environment"
require 'rspec/rails'
require 'capybara'
require 'database_cleaner'
require 'rspec/retry'
require 'paper_trail/frameworks/rspec'

# Allow connections to phantomjs/selenium whilst raising errors
# when connecting to external sites
require 'webmock/rspec'
WebMock.disable_net_connect!(:allow_localhost => true)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/capybara_ext'
require 'spree/api/testing_support/setup'
require 'spree/api/testing_support/helpers'
require 'spree/api/testing_support/helpers_decorator'
require 'spree/testing_support/authorization_helpers'

# Capybara config
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

Capybara.register_driver :poltergeist do |app|
  options = {phantomjs_options: ['--load-images=no'], window_size: [1280, 3600], timeout: 2.minutes}
  # Extend poltergeist's timeout to allow ample time to use pry in browser thread
  #options.merge! {timeout: 5.minutes}
  # Enable the remote inspector: Use page.driver.debug to open a remote debugger in chrome
  #options.merge! {inspector: true}
  Capybara::Poltergeist::Driver.new(app, options)
end

Capybara.default_max_wait_time = 30

require "paperclip/matchers"

# Override setting in Spree engine: Spree::Core::MailSettings
ActionMailer::Base.default_url_options[:host] = 'test.host'

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

  # Filters
  config.filter_run_excluding :skip => true, :future => true, :to_figure_out => true

  # Retry
  config.verbose_retry = true

  # DatabaseCleaner
  config.before(:suite)          { DatabaseCleaner.clean_with :deletion, {except: ['spree_countries', 'spree_states']} }
  config.before(:each)           { DatabaseCleaner.strategy = :transaction }
  config.before(:each, js: true) { DatabaseCleaner.strategy = :deletion, {except: ['spree_countries', 'spree_states']} }
  config.before(:each)           { DatabaseCleaner.start }
  config.after(:each)            { DatabaseCleaner.clean }
  config.after(:each, js:true) do
    Capybara.reset_sessions!
    RackRequestBlocker.wait_for_requests_complete
    DatabaseCleaner.clean
  end

  def restart_phantomjs
    Capybara.send('session_pool').values
      .select { |s| s.driver.is_a?(Capybara::Poltergeist::Driver) }
      .each { |s| s.driver.restart}
  end

  config.before(:all) { restart_phantomjs }

  # Geocoding
  config.before(:each) { allow_any_instance_of(Spree::Address).to receive(:geocode).and_return([1,1]) }

  # Ensure we start with consistent config settings
  config.before(:each) { Spree::Config.products_require_tax_category = false }

  # Helpers
  config.include Rails.application.routes.url_helpers
  config.include Spree::UrlHelpers
  config.include Spree::CheckoutHelpers
  config.include Spree::MoneyHelper
  config.include Spree::TestingSupport::ControllerRequests, :type => :controller
  config.include Devise::TestHelpers, :type => :controller
  config.extend  Spree::Api::TestingSupport::Setup, :type => :controller
  config.include Spree::Api::TestingSupport::Helpers, :type => :controller
  config.include OpenFoodNetwork::ControllerHelper, :type => :controller
  config.include OpenFoodNetwork::FeatureToggleHelper
  config.include OpenFoodNetwork::FiltersHelper
  config.include OpenFoodNetwork::EnterpriseGroupsHelper
  config.include OpenFoodNetwork::ProductsHelper
  config.include OpenFoodNetwork::DistributionHelper
  config.include OpenFoodNetwork::HtmlHelper
  config.include ActionView::Helpers::DateHelper
  config.include OpenFoodNetwork::DelayedJobHelper
  config.include OpenFoodNetwork::PerformanceHelper

  # FactoryGirl
  require 'factory_girl_rails'
  config.include FactoryGirl::Syntax::Methods

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

  #require 'perftools'
  #config.before :suite do
  #  PerfTools::CpuProfiler.start("/tmp/rspec_profile")
  #end
  #
  #config.after :suite do
  # PerfTools::CpuProfiler.stop
  #end
end
