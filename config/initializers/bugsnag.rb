Bugsnag.configure do |config|
  config.api_key = "937a200f492fad600b4cc29dddda5f71"
  config.notify_release_stages = %w(production staging)
  config.use_ssl = true
end
