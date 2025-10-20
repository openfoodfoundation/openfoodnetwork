require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # PROFILE switches several settings to a more "production-like" value
  # for profiling and benchmarking the application locally. All changes you
  # make to the app will require restart.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = !!ENV["PROFILE"]

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
  #
  # To override this, set the appropriate locale in .env[.*] file.
  config.time_zone = ENV.fetch("TIMEZONE", "UTC")

  # Log level for dev server stdout and development.log file.
  # Set the desired level in .env.development.local file.
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", :debug)

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist? || !!ENV["PROFILE"] || !!ENV["DEV_CACHING"]
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :redis_cache_store, {
      url: ENV.fetch("OFN_REDIS_URL", "redis://localhost:6379/1"),
      expires_in: 90.minutes
    }
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  config.action_controller.default_url_options = {host: "localhost", port: 3000}

  # Store uploaded files on the local file system (see config/storage.yml for options).
  # config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Show emails using Letter Opener
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.default_url_options = { host: "localhost:3000" }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

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

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  config.i18n.fallbacks = [:en]

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  # config.action_controller.raise_on_missing_callback_actions = true
end
