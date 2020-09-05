# frozen_string_literal: true

module Spree
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Spree
      engine_name 'spree'

      config.autoload_paths += %W(#{config.root}/lib)

      # We reload the routes here
      #   so that the appended/prepended routes are available to the application.
      config.after_initialize do
        Rails.application.routes_reloader.reload!
      end

      initializer "spree.environment", before: :load_config_initializers do |app|
        app.config.spree = Spree::Core::Environment.new
        Spree::Config = app.config.spree.preferences # legacy access
      end

      initializer "spree.load_preferences", before: "spree.environment" do
        ::ActiveRecord::Base.include Spree::Preferences::Preferable
      end

      initializer "spree.register.payment_methods" do |app|
        app.config.spree.payment_methods = [
          Spree::Gateway::Bogus,
          Spree::Gateway::BogusSimple,
          Spree::PaymentMethod::Check
        ]
      end

      initializer "spree.mail.settings" do |_app|
        Spree::Core::MailSettings.init
        Mail.register_interceptor(Spree::Core::MailInterceptor)
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
    end
  end
end
