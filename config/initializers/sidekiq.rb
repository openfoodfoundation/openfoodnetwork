if Rails.env.production? || Rails.env.staging?
  redis_jobs_url = ENV.fetch("OFN_REDIS_JOBS_URL", "redis://localhost:6381/0")

  Sidekiq.configure_server do |config|
    config.redis = { url: redis_jobs_url }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: redis_jobs_url }
  end
end
