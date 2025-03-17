# frozen_string_literal: true

# Additional config to /spec/system/support/cuprite_setup
RSpec.configure do |config|
  # Make sure url helpers use the Capybara server host.
  config.around(:each, type: :system) do |example|
    original_host = DfcProvider::Engine.routes.default_url_options[:host]
    server = Capybara.current_session.server

    DfcProvider::Engine.routes.default_url_options[:host] = "#{server.host}:#{server.port}"
    example.run
    DfcProvider::Engine.routes.default_url_options[:host] = original_host
    remove_downloaded_files
  end
end
