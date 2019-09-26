if ENV['DATADOG_RAILS_APM']
  Datadog.configure do |c|
    c.use :rails, service_name: 'rails', analytics_enabled: true
    c.use :delayed_job, service_name: 'delayed_job', analytics_enabled: true
    c.use :dalli, service_name: 'memcached', analytics_enabled: true
  end
end
