# frozen_string_literal: true

module Spree
  module Core
    module ControllerHelpers
      module Common
        extend ActiveSupport::Concern
        included do
          helper_method :title
          helper_method :title=
          helper_method :accurate_title

          layout :get_layout

          before_action :set_user_language

          protected

          # This can be used in views as well as controllers.
          # e.g. <% self.title = 'This is a custom title for this view' %>
          attr_writer :title

          def title
            title_string = @title.presence || accurate_title
            if title_string.present?
              [title_string, default_title].join(' - ')
            else
              default_title
            end
          end

          def default_title
            Spree::Config[:site_name]
          end

          # This is a hook for subclasses to provide title
          def accurate_title
            Spree::Config[:default_seo_title]
          end

          def render_404(_exception = nil)
            respond_to do |type|
              type.html {
                render status: :not_found,
                       file: Rails.root.join("public/404.html"),
                       formats: [:html],
                       layout: nil
              }
              type.all { render status: :not_found, body: nil }
            end
          end

          private

          def set_user_language
            locale = session[:locale]
            locale ||= config_locale if respond_to?(:config_locale, true)
            locale ||= Rails.application.config.i18n.default_locale
            unless I18n.available_locales.map(&:to_s).include?(locale)
              locale ||= I18n.default_locale
            end
            I18n.locale = locale
          end

          # Returns which layout to render.
          #   The layout to render can be set inside Spree configuration with the +:layout+ option.
          # Default layout is: +app/views/spree/layouts/spree_application+
          def get_layout
            Spree::Config[:layout]
          end
        end
      end
    end
  end
end
