# frozen_string_literal: true

# Rails standard class for common job code.
class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

  def enable_active_storage_urls
    ActiveStorage::Current.url_options ||=
      Rails.application.config.action_controller.default_url_options
  end
end
