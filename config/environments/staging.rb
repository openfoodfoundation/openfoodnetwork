Openfoodnetwork::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  config.eager_load = true

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.public_file_server.enabled = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Use https in email links
  config.action_mailer.default_url_options = { protocol: 'https' }

  # Set log level (default is :debug in Rails 4)
  config.log_level = :info

  # Configure logging:
  config.log_formatter = Logger::Formatter.new.tap { |f| f.datetime_format = "%Y-%m-%d %H:%M:%S" }

  # Use a different cache store in production
  config.cache_store = :redis_cache_store, {
    driver: :hiredis,
    url: ENV.fetch("OFN_REDIS_URL", "redis://localhost:6380/0"),
    reconnect_attempts: 1
  }

  config.action_cable.url = "#{ENV['OFN_URL']}/cable"
  config.action_cable.allowed_request_origins = [/http:\/\/#{ENV['OFN_URL']}\/*/, /https:\/\/#{ENV['OFN_URL']}\/*/]

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = [:en]

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
end
