require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Turn false under Spring and add config.action_view.cache_template_loading = true.
  config.cache_classes = false

  # Eager loading loads your whole application. When running a single test locally,
  # this probably isn't necessary. It's a good idea to do in a continuous integration
  # system, or in some way before deploying your code.
  # config.eager_load = ENV["CI"].present?
  config.eager_load = false

  config.time_zone = ENV.fetch("TIMEZONE", "UTC")

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Separate cache stores when running in parallel
  config.cache_store = :redis_cache_store, {
     # Unique database number to avoid conflict with others
    url: ENV.fetch("OFN_REDIS_TEST_URL", "redis://localhost:6379/3"),
    reconnect_attempts: 1
  }

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

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

  # Fail tests on deprecated code unless it's a known case to solve.
  Rails.application.deprecators.behavior = ->(message, callstack, deprecator) do
    allowed_warnings = [
      # List strings here to allow matching deprecations.
      #
      # https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#new-activesupport-cache-serialization-format
      "config.active_support.cache_format_version",

      # `Rails.application.secrets` is deprecated in favor of `Rails.application.credentials` and will be removed in Rails 7.2
      "Rails.application.secrets",

      "Passing the class as positional argument",

      # Spree::Order model aliases `bill_address`, but `bill_address` is not an attribute. Starting in Rails 7.2, alias_attribute with non-attribute targets will raise. Use `alias_method :billing_address, :bill_address` or define the method manually. (called from initialize at app/models/spree/order.rb:188)
      "alias_attribute with non-attribute targets will raise",

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

  config.active_job.queue_adapter = :test
end
