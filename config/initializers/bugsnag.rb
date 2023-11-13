Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_API_KEY']
  config.release_stage = Rails.env
  # Avoid missing API key warning without changing the Rails log level.
  if Rails.env.development?
    config.logger = Logger.new(STDOUT)
    config.logger.level = Logger::ERROR
  end
  config.notify_release_stages = %w(production staging)
end
