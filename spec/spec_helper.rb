require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara'
require 'database_cleaner'


Spork.prefork do
  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

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

    config.before(:suite) do
      DatabaseCleaner.strategy = :truncation, { :except => ['spree_countries', 'spree_states'] }
    end

    config.before(:each) do
      DatabaseCleaner.start
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end

    config.include Spree::UrlHelpers
  end
end

Spork.each_run do
  # Dir["#{File.dirname(__FILE__)}/../app/**/*.rb"].each {|f| load f}
  # Rails.application.reload_routes!
end
