require 'simplecov'
SimpleCov.start


require 'rubygems'

# Require pry when we're not inside Travis-CI
require 'pry' unless ENV['HAS_JOSH_K_SEAL_OF_APPROVAL']

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara'
require 'database_cleaner'

# Allow connections to phantomjs/selenium whilst raising errors
# when connecting to external sites
require 'webmock/rspec'
WebMock.disable_net_connect!(:allow_localhost => true)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
require 'spree/core/testing_support/controller_requests'
require 'spree/core/testing_support/capybara_ext'

require 'active_record/fixtures'
fixtures_dir = File.expand_path('../../db/default', __FILE__)
ActiveRecord::Fixtures.create_fixtures(fixtures_dir, ['spree/states', 'spree/countries'])

# Capybara config
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

# For debugging, extend poltergeist's timeout
# Capybara.register_driver :poltergeist do |app|
#   Capybara::Poltergeist::Driver.new(app, timeout: 5.minutes)
# end


require "paperclip/matchers"

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

  # ## Filters
  #
  config.filter_run_excluding :skip => true, :future => true, :to_figure_out => true

  config.before(:each) do
    Spree::Address.any_instance.stub(:geocode).and_return([1,1])

    if example.metadata[:js]
      DatabaseCleaner.strategy = :deletion, { :except => ['spree_countries', 'spree_states'] }
    else
      DatabaseCleaner.strategy = :transaction
    end

    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.include Rails.application.routes.url_helpers
  config.include Spree::UrlHelpers
  config.include Spree::CheckoutHelpers
  config.include Spree::Core::TestingSupport::ControllerRequests, :type => :controller
  config.include Devise::TestHelpers, :type => :controller
  config.include OpenFoodNetwork::FeatureToggleHelper
  config.include OpenFoodNetwork::EnterpriseGroupsHelper
  config.include ActionView::Helpers::DateHelper

  # Factory girl
  require 'factory_girl_rails'
  config.include FactoryGirl::Syntax::Methods

  config.include Paperclip::Shoulda::Matchers

  config.include JsonSpec::Helpers
end
