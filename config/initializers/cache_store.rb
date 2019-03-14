unless Rails.env.production?
  # Enable cache instrumentation, which is disabled by default
  ActiveSupport::Cache::Store.instrument = true

  # Log message in the same default logger
  ActiveSupport::Cache::Store.logger = Rails.logger
end
