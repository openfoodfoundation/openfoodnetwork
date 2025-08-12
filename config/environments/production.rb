require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Enable threaded mode
  # config.threadsafe!

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  # We set it in application.rb.
  # config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  config.action_cable.url = "#{ENV['OFN_URL']}/cable"
  config.action_cable.allowed_request_origins = [/http:\/\/#{ENV['OFN_URL']}\/*/, /https:\/\/#{ENV['OFN_URL']}\/*/]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Include generic and useful information about system operation, but avoid logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII).
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]
  config.log_formatter = Logger::Formatter.new.tap { |f| f.datetime_format = "%Y-%m-%d %H:%M:%S" }

  # Use a different cache store in production.
  config.cache_store = :redis_cache_store, {
    url: ENV.fetch("OFN_REDIS_URL", "redis://localhost:6380/0"),
    reconnect_attempts: 1
  }

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "openfoodnetwork_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Use https in email links
  config.action_mailer.default_url_options = { protocol: 'https' }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = [:en]

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end
