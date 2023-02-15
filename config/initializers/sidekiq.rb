# Redis connection configuration for Sidekiq

redis_connection_settings = {
  url: ENV.fetch("OFN_REDIS_JOBS_URL", "redis://localhost:6381/0"),
  network_timeout: 5,
}

Sidekiq.configure_server do |config|
  config.redis = redis_connection_settings
end

Sidekiq.configure_client do |config|
  config.redis = redis_connection_settings
end
