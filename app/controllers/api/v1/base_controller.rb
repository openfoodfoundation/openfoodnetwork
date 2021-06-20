# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include CanCan::ControllerAdditions
      check_authorization

      attr_accessor :current_api_user

      before_action :authenticate_user

      rescue_from Exception, with: :error_during_processing
      rescue_from CanCan::AccessDenied, with: :unauthorized
      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      private

      def spree_current_user
        @spree_current_user ||= request.env['warden'].user
      end

      # Use logged in user (spree_current_user) for API authentication (current_api_user)
      def authenticate_user
        return if (@current_api_user = spree_current_user)

        if api_key.blank?
          # An anonymous user
          @current_api_user = Spree.user_class.new
          return
        end

        return if (@current_api_user = Spree.user_class.find_by(spree_api_key: api_key.to_s))

        invalid_api_key
      end

      def error_during_processing(exception)
        Bugsnag.notify(exception)

        render json: { exception: exception.message },
               status: :unprocessable_entity
      end

      def current_ability
        Spree::Ability.new(current_api_user)
      end

      def api_key
        request.headers["X-Spree-Token"] || params[:token]
      end
      helper_method :api_key

      def invalid_resource!(resource)
        render json: { error: I18n.t(:invalid_resource, scope: "spree.api"),
                       errors: resource.errors },
               status: :unprocessable_entity
      end

      def invalid_api_key
        render json: { error: I18n.t(:invalid_api_key, key: api_key, scope: "spree.api") },
               status: :unauthorized
      end

      def unauthorized
        render json: { error: I18n.t(:unauthorized, scope: "spree.api") },
               status: :unauthorized
      end

      def not_found
        render json: { error: I18n.t(:resource_not_found, scope: "spree.api") },
               status: :not_found
      end
    end
  end
end
