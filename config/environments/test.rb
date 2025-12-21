require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # StimulusReflex requires caching to be enabled.
  config.cache_classes = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  # config.eager_load = ENV["CI"].present?
  config.eager_load = false

  config.time_zone = ENV.fetch("TIMEZONE", "UTC")

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  # config.cache_store = :null_store

  # Separate cache stores when running in parallel
  config.cache_store = :redis_cache_store, {
     # Unique database number to avoid conflict with others
    url: ENV.fetch("OFN_REDIS_TEST_URL", "redis://localhost:6379/3"),
    reconnect_attempts: 1
  }

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  # config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  # config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Reduced logging by default; set the desired level in .env.test.local file.
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", :fatal)

  # Fail tests on deprecated code unless it's a known case to solve.
  Rails.application.deprecators.behavior = ->(message, callstack, deprecator) do
    allowed_warnings = [
      # List strings here to allow matching deprecations.
      #
      "Passing the class as positional argument",

      # Spree::CreditCard model aliases `cc_type` and has a method called `cc_type=` defined. Starting in Rails 7.2 `brand=` will not be calling `cc_type=` anymore. You may want to additionally define `brand=` to preserve the current behavior.
      "model aliases",

      # Setting action_dispatch.show_exceptions to true is deprecated. Set to :all instead.
      # spec/requests/errors_spec.rb
      "action_dispatch.show_exceptions",
    ]
    unless allowed_warnings.any? { |pattern| message.match(pattern) }
      ActiveSupport::Deprecation::DEFAULT_BEHAVIORS[:raise].call(message, callstack, deprecator)
    end
  end

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Tests assume English text on the site.
  config.i18n.default_locale = "en"
  config.i18n.available_locales = ['en', 'es', 'pt']
  config.i18n.fallbacks = [:en]
  I18n.locale = config.i18n.locale = config.i18n.default_locale

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions
  # config.action_controller.raise_on_missing_callback_actions = true

  config.active_job.queue_adapter = :test
end
