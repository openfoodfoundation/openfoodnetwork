# frozen_string_literal: true

require "base_spec_helper"

RSpec.configure do |config|
  # Set up a fake ToS file
  config.before(:each, type: :system) do
    allow(TermsOfServiceFile).to receive(:updated_at).and_return(2.hours.ago)
  end
end

# system/support/ files contain system tests configurations and helpers
Dir[File.join(__dir__, "system/support/**/*.rb")].sort.each { |file| require file }
