# Redis connection configuration for Sidekiq

redis_connection_settings = {
  url: ENV.fetch("OFN_REDIS_JOBS_URL", "redis://localhost:6381/0"),
  network_timeout: 5,
}

Sidekiq.configure_server do |config|
  config.redis = redis_connection_settings
  config.on(:startup) do
    # Load schedule file similar to sidekiq/cli.rb loading the main config.
    path = File.expand_path("../sidekiq_scheduler.yml", __dir__)
    erb = ERB.new(File.read(path), trim_mode: "-")

    Sidekiq.schedule =
      YAML.safe_load(erb.result, permitted_classes: [Symbol], aliases: true)
    SidekiqScheduler::Scheduler.instance.reload_schedule!
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_connection_settings
end
