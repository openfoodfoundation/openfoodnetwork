# frozen_string_literal: true

require "rack/test"

headless = ActiveModel::Type::Boolean.new.cast(ENV.fetch("HEADLESS", true))

Capybara.register_driver(:rack) do |app|
  Capybara::RackTest::Driver.new(
    app,
    **{
      respect_data_method: false,
      follow_redirects: true,
      redirect_limit: 5
    }.freeze
  )
end

# Configure Capybara to use :cuprite driver by default
Capybara.default_driver = :rack

RSpec.configure do |config|
  config.include Rack::Test::Methods
end