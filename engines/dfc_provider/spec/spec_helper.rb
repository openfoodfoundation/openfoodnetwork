# frozen_string_literal: true

require_relative '../../../spec/spec_helper'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.around(:each) do |example|
    # The DFC Connector fetches the context when loaded.
    VCR.use_cassette("dfc-conext") do
      example.run
    end
  end
end
