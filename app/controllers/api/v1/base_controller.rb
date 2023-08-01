# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include CanCan::ControllerAdditions
      include RequestTimeouts
      include Pagy::Backend
      include JsonApiPagination
      include RaisingParameters

      check_authorization

      attr_accessor :current_api_user

      before_action :authenticate_user
      before_action :restrict_feature

      rescue_from StandardError, with: :error_during_processing
      rescue_from CanCan::AccessDenied, with: :unauthorized
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from Pagy::VariableError, with: :invalid_pagination
      rescue_from ActionController::ParameterMissing, with: :missing_parameter
      rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameters

      private

      def authenticate_user
        return if (@current_api_user = request.env['warden'].user)

        if api_key.blank?
          # An anonymous user
          @current_api_user = Spree::User.new
          return
        end

        return if (@current_api_user = Spree::User.find_by(spree_api_key: api_key.to_s))

        invalid_api_key
      end

      def restrict_feature
        not_found unless OpenFoodNetwork::FeatureToggle.enabled?(:api_v1, @current_api_user)
      end

      def current_ability
        Spree::Ability.new(current_api_user)
      end

      def api_key
        request.headers["X-Api-Token"] || params[:token]
      end

      def error_during_processing(exception)
        Bugsnag.notify(exception)

        if Rails.env.development? || Rails.env.test?
          render status: :unprocessable_entity,
                 json: json_api_error(exception.message, meta: exception.backtrace)
        else
          render status: :unprocessable_entity,
                 json: json_api_error(I18n.t(:unknown_error, scope: "api"))
        end
      end

      def invalid_pagination(exception)
        render status: :unprocessable_entity,
               json: json_api_error(exception.message)
      end

      def missing_parameter(error)
        message = I18n.t('api.missing_parameter', param: error.param)

        render status: :unprocessable_entity,
               json: json_api_error(message)
      end

      def unpermitted_parameters(error)
        message = I18n.t('api.unpermitted_parameters', params: error.params.join(", "))

        render status: :unprocessable_entity,
               json: json_api_error(message)
      end

      def invalid_resource!(resource = nil)
        render status: :unprocessable_entity,
               json: json_api_invalid(
                 I18n.t(:invalid_resource, scope: "api"),
                 resource&.errors
               )
      end

      def invalid_api_key
        render status: :unauthorized,
               json: json_api_error(I18n.t(:invalid_api_key, key: api_key, scope: "api"))
      end

      def unauthorized
        render status: :unauthorized,
               json: json_api_error(I18n.t(:unauthorized, scope: "api"))
      end

      def not_found
        render status: :not_found,
               json: json_api_error(I18n.t(:resource_not_found, scope: "api"))
      end

      def json_api_error(message, **options)
        error_options = options.delete(:error_options) || {}

        { errors: [{ detail: message }.merge(error_options)] }.merge(options)
      end

      def json_api_invalid(message, errors)
        error_response = { errors: [{ detail: message }] }
        error_response.merge!(meta: { validation_errors: errors.to_a }) if errors.any?
        error_response
      end
    end
  end
end
