require_relative 'boot'

require "rails"
[
  "active_record/railtie",
  "active_storage/engine",
  "action_controller/railtie",
  "action_view/railtie",
  "action_mailer/railtie",
  "active_job/railtie",
  "action_cable/engine",
  #"action_mailbox/engine",
  #"action_text/engine",
  "rails/test_unit/railtie",
  "sprockets/railtie" # Disable this after migrating to Webpacker
].each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end

require_relative "../lib/open_food_network/i18n_config"
require_relative '../lib/spree/core/environment'
require_relative '../lib/spree/core/mail_interceptor'
require_relative "../lib/session_cookie_upgrader"

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Openfoodnetwork
  class Application < Rails::Application
    config.middleware.insert_before(
      ActionDispatch::Cookies,
      SessionCookieUpgrader, {
        old_key: "_session_id",
        new_key: "_ofn_session_id",
        domain: ".#{ENV['SITE_URL'].gsub(/^(www\.)|^(app\.)|^(staging\.)|^(stg\.)/, '')}"
      }
    ) if Rails.env.staging? || Rails.env.production?

    config.after_initialize do
      # We need this here because the test env file loads before the Spree engine is loaded
      Spree::Core::Engine.routes.default_url_options[:host] = ENV["SITE_URL"] if Rails.env == 'test'
    end

    # We reload the routes here
    #   so that the appended/prepended routes are available to the application.
    config.after_initialize do
      Rails.application.routes_reloader.reload!
    end

    initializer "spree.environment", before: :load_config_initializers do |app|
      Rails.application.reloader.to_prepare do
        app.config.spree = Spree::Core::Environment.new
        Spree::Config = app.config.spree.preferences # legacy access
      end
    end

    initializer "spree.register.payment_methods" do |app|
      Rails.application.reloader.to_prepare do
        app.config.spree.payment_methods = [
          Spree::Gateway::Bogus,
          Spree::Gateway::BogusSimple,
          Spree::PaymentMethod::Check
        ]
      end
    end

    initializer "spree.mail.settings" do |_app|
      Rails.application.reloader.to_prepare do
        Spree::Core::MailSettings.init
        Mail.register_interceptor(Spree::Core::MailInterceptor)
      end
    end

    # filter sensitive information during logging
    initializer "spree.params.filter" do |app|
      app.config.filter_parameters += [
        :password,
        :password_confirmation,
        :number,
        :verification_value
      ]
    end

    # Settings dependent on locale
    #
    # We need to set this config before the promo environment gets loaded and
    # after the spree environment gets loaded...
    # This is because Spree uses `Spree::Config` while evaluating classes :scream:
    #
    # https://github.com/spree/spree/blob/2-0-stable/core/app/models/spree/calculator/per_item.rb#L6
    #
    # TODO: move back to spree initializer once we upgrade to a more recent version
    #       of Spree
    initializer 'ofn.spree_locale_settings', before: 'spree.promo.environment' do |app|
      Rails.application.reloader.to_prepare do
        Spree::Config['checkout_zone'] = ENV['CHECKOUT_ZONE']
        Spree::Config['currency'] = ENV['CURRENCY']
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

    # Register Spree payment methods
    initializer "spree.gateway.payment_methods", :after => "spree.register.payment_methods" do |app|
      Rails.application.reloader.to_prepare do
        app.config.spree.payment_methods << Spree::Gateway::StripeSCA
        app.config.spree.payment_methods << Spree::Gateway::PayPalExpress
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

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = ENV["TIMEZONE"]

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = OpenFoodNetwork::I18nConfig.default_locale
    config.i18n.available_locales = OpenFoodNetwork::I18nConfig.available_locales
    I18n.locale = config.i18n.locale = config.i18n.default_locale

    # Setting this to true causes a performance regression in Rails 3.2.17
    # When we're on a version with the fix below, we can set it to true
    # https://github.com/svenfuchs/i18n/issues/230
    I18n.config.enforce_available_locales = false

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.2'

    # Unset X-Frame-Options header for embedded pages.
    config.action_dispatch.default_headers.except! "X-Frame-Options"

    # css and js files other than application.* are not precompiled by default
    # Instead, they must be explicitly included below
    # http://stackoverflow.com/questions/8012434/what-is-the-purpose-of-config-assets-precompile
    config.assets.initialize_on_precompile = true
    config.assets.precompile += ['admin/*.js', 'admin/**/*.js']
    config.assets.precompile += ['web/all.js']
    config.assets.precompile += ['darkswarm/all.js']
    config.assets.precompile += ['shared/*']
    config.assets.precompile += ['*.jpg', '*.jpeg', '*.png', '*.gif' '*.svg']

    # Apply framework defaults. New recommended defaults are successively added with each Rails version and
    # include the defaults from previous versions. For more info see:
    # https://guides.rubyonrails.org/configuring.html#results-of-config-load-defaults
    config.load_defaults 6.1
    config.action_view.form_with_generates_remote_forms = false
    config.active_record.belongs_to_required_by_default = false
    config.active_record.cache_versioning = false
    config.active_record.has_many_inversing = false
    config.active_record.yaml_column_permitted_classes = [BigDecimal, Symbol]

    config.active_support.escape_html_entities_in_json = true

    config.active_job.queue_adapter = :sidekiq

    config.action_controller.include_all_helpers = false

    config.generators.template_engine = :haml

    Rails.application.routes.default_url_options[:host] = ENV["SITE_URL"]
    DfcProvider::Engine.routes.default_url_options[:host] = ENV["SITE_URL"]

    Rails.autoloaders.main.ignore(Rails.root.join('app/webpacker'))

    config.active_storage.service = ENV["S3_BUCKET"].present? ? :amazon : :local
    config.active_storage.content_types_to_serve_as_binary -= ["image/svg+xml"]
    config.active_storage.variable_content_types += ["image/svg+xml"]

    config.exceptions_app = self.routes

    config.autoloader = :zeitwerk
  end
end
