if ENV['DATADOG_RAILS_APM']
  Datadog.configure do |c|
    c.use :rails, service_name: 'rails'

    c.analytics_enabled = true
    c.runtime_metrics_enabled = true

    c[:rack].request_queuing = true
  end
end
