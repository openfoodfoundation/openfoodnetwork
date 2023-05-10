# frozen_string_literal: true

require_relative '../../../spec/spec_helper'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.include AuthorizationHelper, type: :request
  config.include DfcProvider::Engine.routes.url_helpers, type: :request

  config.around(:each) do |example|
    # The DFC Connector fetches the context when loaded.
    VCR.use_cassette("dfc-context") do
      example.run
    end
  end
end
