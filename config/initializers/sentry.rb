if ENV["SENTRY_ENDPOINT"]
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_ENDPOINT"]
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.send_default_pii = true

    # Set traces_sample_rate to 1.0 to capture 100%
    # of transactions for performance monitoring.
    # We recommend adjusting this value in production.
    config.traces_sample_rate = ENV.fetch("SENTRY_SAMPLE_RATE", 1.0).to_f
  end
end
