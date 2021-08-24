# frozen_string_literal: true

require "base_spec_helper_system"

# system/support/ files contain system tests configurations and helpers
Dir[File.join(__dir__, "system/support/**/*.rb")].sort.each { |file| require file }
