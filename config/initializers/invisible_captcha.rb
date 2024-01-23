# frozen_string_literal: true

InvisibleCaptcha.setup do |config|
  # Disable timestamp check for test environment
  config.timestamp_enabled = !Rails.env.test?
end
