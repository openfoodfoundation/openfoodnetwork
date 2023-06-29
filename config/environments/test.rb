Openfoodnetwork::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = false

  config.eager_load = false

  # Configure static asset server for tests with Cache-Control for performance
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }

  # Separate cache stores when running in parallel
  config.cache_store = :redis_cache_store, {
    driver: :hiredis,
     # Unique database number to avoid conflict with others
    url: ENV.fetch("OFN_REDIS_TEST_URL", "redis://localhost:6379/3"),
    reconnect_attempts: 1
  }

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Tests should fail when translations are missing.
  config.i18n.raise_on_missing_translations = true

  config.time_zone = ENV.fetch("TIMEZONE", "UTC")

  # Tests assume English text on the site.
  config.i18n.default_locale = "en"
  config.i18n.available_locales = ['en', 'es', 'pt']
  config.i18n.fallbacks = [:en]
  I18n.locale = config.i18n.locale = config.i18n.default_locale

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  config.active_job.queue_adapter = :test

  config.active_storage.service = :test
end
