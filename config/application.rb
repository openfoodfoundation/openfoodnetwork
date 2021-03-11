require_relative 'boot'

require 'rails/all'
require_relative "../lib/open_food_network/i18n_config"

require_relative '../lib/spree/core/environment'
require_relative '../lib/spree/core/mail_interceptor'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Openfoodnetwork
  class Application < Rails::Application

    config.to_prepare do
      # Load application's model / class decorators
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.after_initialize do
      # We need this here because the test env file loads before the Spree engine is loaded
      Spree::Core::Engine.routes.default_url_options[:host] = 'test.host' if Rails.env == 'test'
    end

    # We reload the routes here
    #   so that the appended/prepended routes are available to the application.
    config.after_initialize do
      Rails.application.routes_reloader.reload!
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(
      #{config.root}/app/models/concerns
      #{config.root}/app/presenters
      #{config.root}/app/jobs
    )

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

    config.sass.load_paths += [
      "#{Gem.loaded_specs['foundation-rails'].full_gem_path}/vendor/assets/stylesheets/foundation/components",
      "#{Gem.loaded_specs['foundation-rails'].full_gem_path}/vendor/assets/stylesheets/foundation/"
    ]

    # css and js files other than application.* are not precompiled by default
    # Instead, they must be explicitly included below
    # http://stackoverflow.com/questions/8012434/what-is-the-purpose-of-config-assets-precompile
    config.assets.initialize_on_precompile = true
    config.assets.precompile += ['iehack.js']
    config.assets.precompile += ['admin/all.css', 'admin/*.js', 'admin/**/*.js']
    config.assets.precompile += ['web/all.css', 'web/all.js']
    config.assets.precompile += ['darkswarm/all.css', 'darkswarm/all.js']
    config.assets.precompile += ['mail/all.css']
    config.assets.precompile += ['shared/*']
    config.assets.precompile += ['qz/*']
    config.assets.precompile += ['*.jpg', '*.jpeg', '*.png', '*.gif' '*.svg']

    config.active_support.escape_html_entities_in_json = true

    config.active_job.queue_adapter = :delayed_job

    config.action_controller.include_all_helpers = false
  end
end
