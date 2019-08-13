if ENV['DATADOG_RAILS_APM']
  Datadog.configure do |c|
    c.use :rails, service_name: 'rails'
  end
end
