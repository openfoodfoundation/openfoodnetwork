require 'ddtrace'

if ENV['DATADOG_RAILS_APM']
  Datadog.configure do |c|
    c.tracing.instrument :rails, service_name: 'rails'

    c.tracing.analytics.enabled = true
    c.runtime_metrics.enabled = true

    c[:rack].request_queuing = true
  end
end
