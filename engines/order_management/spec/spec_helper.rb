ENV["RAILS_ENV"] = "test"

require "order_management"
require "../../spec/spec_helper"

# Require factories in Spree and main application.
require 'spree/testing_support/factories'
require '../../spec/factories'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
