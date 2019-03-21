Openfoodnetwork::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # :file_store is used by default when no cache store is specifically configured.
  # config.cache_store = :file_store

  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = false

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
  #
  # To override this, set the appropriate locale in application.yml
  config.time_zone = ENV.fetch("TIMEZONE", "UTC")

  config.i18n.fallbacks = [:en]

  # Show emails using Letter Opener
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.default_url_options = { host: "0.0.0.0:3000" }

  config.log_level = :debug
end
