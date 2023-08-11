Openfoodnetwork::Application.configure do
  config.action_controller.default_url_options = {host: "localhost", port: 3000}
  # Settings specified here will take precedence over those in config/application.rb
  #
  # PROFILE switches several settings to a more "production-like" value
  # for profiling and benchmarking the application locally. All changes you
  # make to the app will require restart.

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = !!ENV["PROFILE"]

  config.action_controller.default_url_options = {host: "localhost", port: 3000}

  # :file_store is used by default when no cache store is specifically configured.
  if !!ENV["PROFILE"] || !!ENV["DEV_CACHING"]
    config.cache_store = :redis_cache_store, {
      driver: :hiredis,
      url: ENV.fetch("OFN_REDIS_URL", "redis://localhost:6379/1"),
      expires_in: 90.minutes
    }
  end

  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = !!ENV["PROFILE"] || !!ENV["DEV_CACHING"]

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Generate digests for assets URLs.
  #
  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = !!ENV["PROFILE"]

  # Expands the lines which load the assets
  #
  # Setting this to false makes Rails bundle assets into all.js and all.css.
  #
  # Disabling asset debugging still requires that assets be compiled for each
  # request. You can avoid that by precompiling the assets as in production:
  #
  #   $ bundle exec rake assets:precompile:primary assets:precompile:nondigest
  #
  # You can remove them by simply running:
  #
  #   $ bundle exec rake assets:clean
  config.assets.debug = !!ENV["DEBUG_ASSETS"]

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
  #
  # To override this, set the appropriate locale in .env[.*] file.
  config.time_zone = ENV.fetch("TIMEZONE", "UTC")

  config.i18n.fallbacks = [:en]

  # Show emails using Letter Opener
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.default_url_options = { host: "0.0.0.0:3000" }
  config.action_mailer.asset_host = "http://localhost:3000"

  config.log_level = ENV.fetch("DEV_LOG_LEVEL", :debug)
end
