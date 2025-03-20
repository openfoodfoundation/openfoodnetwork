# frozen_string_literal: true

# Load OFN base helpers and system spec support files
require_relative '../../../spec/system_helper'

# Engine-specific spec helpers
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
