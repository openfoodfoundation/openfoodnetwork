Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_API_KEY']
  config.app_version = Rails.application.config.x.git_version

  # Avoid missing API key warning without changing the Rails log level.
  if Rails.env.development?
    config.logger = Logger.new(STDOUT)
    config.logger.level = Logger::ERROR
  end

  # If you want to notify Bugsnag in dev or test then set the env var:
  #   spring stop
  #   BUGSNAG=true ./bin/rails console
  config.enabled_release_stages = %w(production staging) unless ENV["BUGSNAG"]
end
