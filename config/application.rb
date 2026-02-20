require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"
require "sprockets/railtie" # Disable this after migrating to Webpacker

require_relative "../lib/open_food_network/i18n_config"
require_relative '../lib/spree/core/environment'
require_relative '../lib/spree/core/mail_interceptor'
require_relative "../lib/i18n_digests"
require_relative "../lib/git_utils"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups(:assets => %w(development test)))

module Openfoodnetwork
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1
    config.action_view.form_with_generates_remote_forms = false
    config.active_record.cache_versioning = false
    config.active_record.has_many_inversing = false
    config.active_record.yaml_column_permitted_classes = [BigDecimal, Symbol, Time,
                                                          ActiveSupport::TimeWithZone,
                                                          ActiveSupport::TimeZone]
    config.active_support.cache_format_version = 7.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    # config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = ENV["TIMEZONE"]
    # config.eager_load_paths << Rails.root.join("extras")

    # Store a description of the current version
    config.x.git_version = GitUtils::git_version

    config.after_initialize do
      # We need this here because the test env file loads before the Spree engine is loaded
      Spree::Core::Engine.routes.default_url_options[:host] = ENV["SITE_URL"] if Rails.env == 'test'
    end

    config.after_initialize do
      # We reload the routes here
      #   so that the appended/prepended routes are available to the application.
      Rails.application.routes_reloader.reload!

      # Subscribe to payment transition events
      ActiveSupport::Notifications.subscribe(
        "ofn.payment_transition", Payments::StatusChangedListenerService.new
      )
    end

    initializer "spree.environment", before: :load_config_initializers do |app|
      Rails.application.reloader.to_prepare do
        app.config.spree = Spree::Core::Environment.new
        Spree::Config = app.config.spree.preferences # legacy access
      end
    end

    initializer "spree.mail.settings" do |_app|
      Rails.application.reloader.to_prepare do
        Spree::Core::MailSettings.init
        Mail.register_interceptor(Spree::Core::MailInterceptor)
      end
    end

    initializer "load_spree_calculators" do |app|
      # Register Spree calculators
      Rails.application.reloader.to_prepare do
        app.config.spree.calculators.shipping_methods = [
          Calculator::FlatPercentItemTotal,
          Calculator::FlatRate,
          Calculator::FlexiRate,
          Calculator::PerItem,
          Calculator::PriceSack,
          Calculator::Weight,
          Calculator::None
        ]

        app.config.spree.calculators.add_class('enterprise_fees')
        app.config.spree.calculators.enterprise_fees = [
          Calculator::FlatPercentPerItem,
          Calculator::FlatRate,
          Calculator::FlexiRate,
          Calculator::PerItem,
          Calculator::PriceSack,
          Calculator::Weight
        ]

        app.config.spree.calculators.add_class('payment_methods')
        app.config.spree.calculators.payment_methods = [
          Calculator::FlatPercentItemTotal,
          Calculator::FlatRate,
          Calculator::FlexiRate,
          Calculator::PerItem,
          Calculator::PriceSack,
          Calculator::None
        ]

        app.config.spree.calculators.add_class('tax_rates')
        app.config.spree.calculators.tax_rates = [
          Calculator::DefaultTax
        ]
      end
    end

    initializer "ofn.reports" do |app|
      module ::Reporting; end
      Rails.application.reloader.to_prepare do
        next if defined?(::Reporting) && defined?(::Reporting::Errors)

        loader = Zeitwerk::Loader.new
        loader.push_dir("#{Rails.root}/lib/reporting", namespace: ::Reporting)
        loader.enable_reloading
        loader.setup
        loader.eager_load

        if Rails.env.development?
          require 'listen'
          Listen.to("lib/reporting") { loader.reload }.start
        end
      end
    end

    config.paths["config/routes.rb"] = %w(
      config/routes/api.rb
      config/routes.rb
      config/routes/admin.rb
      config/routes/spree.rb
    ).map { |relative_path| Rails.root.join(relative_path) }

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = OpenFoodNetwork::I18nConfig.default_locale
    config.i18n.available_locales = OpenFoodNetwork::I18nConfig.available_locales
    I18n.locale = config.i18n.locale = config.i18n.default_locale

    # Calculate digests for locale files so we can know when they change
    I18nDigests.build_digests config.i18n.available_locales

    # Setting this to true causes a performance regression in Rails 3.2.17
    # When we're on a version with the fix below, we can set it to true
    # https://github.com/svenfuchs/i18n/issues/230
    I18n.config.enforce_available_locales = false

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.initialize_on_precompile = true

    # Unset X-Frame-Options header for embedded pages.
    config.action_dispatch.default_headers.except! "X-Frame-Options"

    # Highlight code that triggered database queries in logs.
    config.active_record.verbose_query_logs = ENV.fetch("VERBOSE_QUERY_LOGS", false)

    config.active_support.escape_html_entities_in_json = true

    config.active_job.queue_adapter = :sidekiq

    config.action_controller.include_all_helpers = false

    config.generators.template_engine = :haml

    Rails.application.routes.default_url_options[:host] = ENV["SITE_URL"]
    DfcProvider::Engine.routes.default_url_options[:host] = ENV["SITE_URL"]

    Rails.autoloaders.main.ignore(Rails.root.join('app/webpacker'))

    config.active_storage.service =
      if ENV["S3_BUCKET"].present?
        if ENV["S3_ENDPOINT"].present?
          :s3_compatible_storage
        else
          :amazon
        end
      else
        :local
      end
    config.active_storage.content_types_to_serve_as_binary -= ["image/svg+xml"]
    config.active_storage.variable_content_types += ["image/svg+xml"]
    config.active_storage.url_options = config.action_controller.default_url_options
    config.active_storage.variant_processor = :mini_magick

    config.exceptions_app = self.routes

    config.view_component.generate.sidecar = true # Always generate components in subfolders

    # Database encryption configuration, required for VINE connected app
    config.active_record.encryption.primary_key = ENV.fetch(
      "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY", nil
    )
    config.active_record.encryption.deterministic_key = ENV.fetch(
      "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY", nil
    )
    config.active_record.encryption.key_derivation_salt = ENV.fetch(
      "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT", nil
    )
  end
end
