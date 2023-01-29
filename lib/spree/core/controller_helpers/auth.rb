# frozen_string_literal: true

module Spree
  module Core
    module ControllerHelpers
      module Auth
        extend ActiveSupport::Concern

        included do
          before_action :ensure_api_key

          rescue_from CanCan::AccessDenied do
            unauthorized
          end
        end

        # Needs to be overriden so that we use Spree's Ability rather than anyone else's.
        def current_ability
          @current_ability ||= Spree::Ability.new(spree_current_user)
        end

        # Redirect as appropriate when an access request fails.  The default action is to redirect
        #   to the login screen. Override this method in your controllers if you want to have
        #   special behavior in case the user is not authorized to access the requested action.
        # For example, a popup window might simply close itself.
        def unauthorized
          if spree_current_user
            flash[:error] = t(:authorization_failure)
            redirect_to '/unauthorized'
          else
            store_location

            redirect_to main_app.root_path(anchor: "/login", after_login: request.original_fullpath)
          end
        end

        def store_location
          # disallow return to login, logout, signup pages
          authentication_routes = [:spree_login_path, :spree_logout_path]
          disallowed_urls = []
          authentication_routes.each do |route|
            if respond_to?(route)
              disallowed_urls << __send__(route)
            end
          end

          disallowed_urls.map!{ |url| url[%r{/\w+$}] }
          return if disallowed_urls.include?(request.fullpath)

          session['spree_user_return_to'] = request.fullpath.gsub('//', '/')
        end

        def return_url_or_default(default)
          session.delete("spree_user_return_to") || default
        end

        # Need to generate an API key for a user due to some actions potentially
        # requiring authentication to the Spree API
        def ensure_api_key
          return unless (user = spree_current_user)

          return unless user.respond_to?(:spree_api_key) && user.spree_api_key.blank?

          user.generate_api_key
          user.save
        end
      end
    end
  end
end
