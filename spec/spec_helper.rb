# frozen_string_literal: true

require 'base_spec_helper'
require 'database_cleaner'

RSpec.configure do |config|
  # Fix encoding issue in Rails 5.0; allows passing empty arrays or hashes as params.
  config.before(:each, type: :controller) { @request.env["CONTENT_TYPE"] = 'application/json' }
end
