# frozen_string_literal: true

require "base_spec_helper"

# system/support/ files contain system tests configurations and helpers
Dir[File.join(__dir__, "system/support/**/*.rb")].each { |file| require file }
