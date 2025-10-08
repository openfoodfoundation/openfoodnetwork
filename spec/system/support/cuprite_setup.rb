# frozen_string_literal: true

require "capybara/cuprite"

headless = ActiveModel::Type::Boolean.new.cast(ENV.fetch("HEADLESS", true))

browser_options = {
  "ignore-certificate-errors" => nil,
}
browser_options["no-sandbox"] = nil if ENV['CI'] || ENV['DOCKER']

Capybara.register_driver(:cuprite_ofn) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1280, 800],
    browser_options:,
    process_timeout: 60,
    timeout: 60,
    # Don't load scripts from external sources, like google maps or stripe
    url_whitelist: [
      %r{^http://localhost}, %r{^http://0.0.0.0}, %r{http://127.0.0.1},

      # Testing the DFC Permissions component by Startin'Blox:
      %r{^https://cdn.jsdelivr.net/npm/@startinblox/},
      %r{^https://cdn.startinblox.com/},
      %r{^https://data-server.cqcm.startinblox.com/scopes$},
      %r{^https://api.proxy-dev.cqcm.startinblox.com/profile$},

      # Just for testing external connections: spec/system/billy_spec.rb
      %r{^https?://deb.debian.org},
    ],
    inspector: true,
    headless:,
    js_errors: true,
    # Puffing Billy seems to make our rspec processes hang at the end.
    # Deactivating for now.
    #
    # proxy: { host: Billy.proxy.host, port: Billy.proxy.port },
  )
end

# Configure Capybara to use :cuprite_ofn driver by default
Capybara.default_driver = Capybara.javascript_driver = :cuprite_ofn

RSpec.configure do |config|
  config.include CupriteHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :system

  config.prepend_before(:each, type: :system) { driven_by :cuprite_ofn }

  # Make sure url helpers in mailers use the Capybara server host.
  config.around(:each, type: :system) do |example|
    original_host = Rails.application.default_url_options[:host]
    Rails.application.default_url_options[:host] =
      "#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"
    DfcProvider::Engine.routes.default_url_options = Rails.application.default_url_options
    example.run
    Rails.application.default_url_options[:host] = original_host
    remove_downloaded_files
  end
end
