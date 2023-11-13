Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_API_KEY']
  config.release_stage = Rails.env
  if Rails.env.development?
    config.logger = Logger.new(STDOUT) # In Rails apps, create a new logger to avoid changing the Rails log level
    config.logger.level = Logger::ERROR
  end
  config.notify_release_stages = %w(production staging)
end
