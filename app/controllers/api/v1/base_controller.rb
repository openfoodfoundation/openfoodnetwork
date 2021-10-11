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

      def current_ability
        Spree::Ability.new(current_api_user)
      end

      def api_key
        request.headers["X-Spree-Token"] || params[:token]
      end

      def error_during_processing(exception)
        Bugsnag.notify(exception)

        render status: :unprocessable_entity,
               json: json_api_error(exception.message, backtrace: exception.backtrace)
      end

      def invalid_resource!(resource = nil)
        render status: :unprocessable_entity,
               json: json_api_invalid(I18n.t(:invalid_resource, scope: "spree.api"), resource&.errors)
      end

      def invalid_api_key
        render status: :unauthorized,
               json: json_api_error(I18n.t(:invalid_api_key, key: api_key, scope: "spree.api"))
      end

      def unauthorized
        render status: :unauthorized,
               json: json_api_error(I18n.t(:unauthorized, scope: "spree.api"))
      end

      def not_found
        render status: :not_found,
               json: json_api_error(I18n.t(:resource_not_found, scope: "spree.api"))
      end

      def json_api_error(message, **options)
        error_response = { errors: [{ detail: message }] }
        if options[:backtrace] && (Rails.env.development? || Rails.env.test?)
          error_response.merge!(meta: [options[:backtrace]])
        end
        error_response
      end

      def json_api_invalid(message, errors)
        error_response = { errors: [{ detail: message }] }
        error_response.merge!(meta: { validation_errors: errors.to_a }) if errors.any?
        error_response
      end
    end
  end
end
