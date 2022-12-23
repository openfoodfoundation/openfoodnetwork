# frozen_string_literal: true

require "capybara/cuprite"

headless = ActiveModel::Type::Boolean.new.cast(ENV.fetch("HEADLESS", true))

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    **{
      window_size: [1200, 800],
      browser_options: { "allow-download": true },
      process_timeout: 20,
      timeout: 20,
      # Don't load scripts from external sources, like google maps or stripe
      url_whitelist: ["http://localhost", "http://0.0.0.0", "http://127.0.0.1"],
      inspector: true,
      headless: headless,
      js_errors: true,
    }
  )
end

# Configure Capybara to use :cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :cuprite

RSpec.configure do |config|
  config.include CupriteHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :system

  config.prepend_before(:each, type: :system) { driven_by :cuprite }

  # System tests use transactional fixtures instead of DatabaseCleaner
  config.use_transactional_fixtures = true

  # Make sure url helpers in mailers use the Capybara server host.
  config.around(:each, type: :system) do |example|
    original_host = Rails.application.default_url_options[:host]
    Rails.application.default_url_options[:host] =
      "#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"
    example.run
    Rails.application.default_url_options[:host] = original_host
    remove_downloaded_files
  end
end
