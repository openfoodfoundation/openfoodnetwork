if ENV['DATADOG_RAILS_APM']
  Datadog.configure do |c|
    c.tracing.instrument :rack, request_queuing: true
    c.tracing.instrument :rails, service_name: 'rails'

    c.tracing.analytics.enabled = true
    c.runtime_metrics.enabled = true
  end
end
