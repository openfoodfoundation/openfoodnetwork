unless Rails.env.production?
  # Log message in the same default logger
  ActiveSupport::Cache::Store.logger = Rails.logger
end
