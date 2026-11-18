# frozen_string_literal: true

module Spree
  module Core
    module ControllerHelpers
      module Common
        extend ActiveSupport::Concern

        included do
          layout :pick_layout

          before_action :set_user_language

          protected

          def render404(_exception = nil)
            respond_to do |type|
              type.html {
                render status: :not_found,
                       file: Rails.public_path.join('404.html'),
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
          def pick_layout
            Spree::Config[:layout]
          end
        end
      end
    end
  end
end
