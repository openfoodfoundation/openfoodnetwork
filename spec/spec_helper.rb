require 'rubygems'

# Require pry when we're not inside Travis-CI
require 'pry' unless ENV['HAS_JOSH_K_SEAL_OF_APPROVAL']

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara'
require 'database_cleaner'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
require 'spree/core/testing_support/controller_requests'

require 'active_record/fixtures'
fixtures_dir = File.expand_path('../../db/default', __FILE__)
ActiveRecord::Fixtures.create_fixtures(fixtures_dir, ['spree/states', 'spree/countries'])


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
  config.filter_run_excluding :skip => true

  config.before(:each) do
    if example.metadata[:js]
      DatabaseCleaner.strategy = :truncation, { :except => ['spree_countries', 'spree_states'] }
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
  config.include Spree::Core::TestingSupport::ControllerRequests, :type => :controller
  config.include Devise::TestHelpers, :type => :controller

  # Factory girl
  require 'factory_girl_rails'
  config.include FactoryGirl::Syntax::Methods
end
