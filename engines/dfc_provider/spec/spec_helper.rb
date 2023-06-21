# frozen_string_literal: true

require_relative '../../../spec/spec_helper'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.include AuthorizationHelper, type: :request
  config.include DfcProvider::Engine.routes.url_helpers, type: :request
  config.include Warden::Test::Helpers, type: :request
end
