# frozen_string_literal: true

# Base controller for OFN's API
require "spree/api/controller_setup"

module Api
  module V0
    class BaseController < ActionController::Metal
      include Pagy::Backend
      include RawParams
      include ActionController::StrongParameters
      include ActionController::RespondWith
      include Spree::Api::ControllerSetup
      include ::ActionController::Head
      include ::ActionController::ConditionalGet
      include ActionView::Layouts
      include RequestTimeouts

      layout false

      attr_accessor :current_api_user

      before_action :set_content_type
      before_action :authenticate_user

      rescue_from Exception, with: :error_during_processing
      rescue_from CanCan::AccessDenied, with: :unauthorized
      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      # Include these because we inherit from ActionController::Metal
      #   rather than ActionController::Base and these are required for AMS
      include ActionController::Serialization
      include ActionController::UrlFor
      include Rails.application.routes.url_helpers

      use_renderers :json
      check_authorization

      def respond_with_conflict(json_hash)
        render json: json_hash, status: :conflict
      end

      private

      def spree_current_user
        @spree_current_user ||= request.env['warden'].user
      end

      # Use logged in user (spree_current_user) for API authentication (current_api_user)
      def authenticate_user
        return if @current_api_user = spree_current_user

        if api_key.blank?
          # An anonymous user
          @current_api_user = Spree::User.new
          return
        end

        return if @current_api_user = Spree::User.find_by(spree_api_key: api_key.to_s)

        invalid_api_key
      end

      def set_content_type
        headers["Content-Type"] = "application/json"
      end

      def error_during_processing(exception)
        Bugsnag.notify(exception)

        render(json: { exception: exception.message },
               status: :unprocessable_entity) && return
      end

      def current_ability
        Spree::Ability.new(current_api_user)
      end

      def api_key
        request.headers["X-Spree-Token"] || params[:token]
      end
      helper_method :api_key

      def invalid_resource!(resource)
        @resource = resource
        render(json: { error: I18n.t(:invalid_resource, scope: "spree.api"),
                       errors: @resource.errors },
               status: :unprocessable_entity)
      end

      def invalid_api_key
        render(json: { error: I18n.t(:invalid_api_key, key: api_key, scope: "spree.api") },
               status: :unauthorized) && return
      end

      def unauthorized
        render(json: { error: I18n.t(:unauthorized, scope: "spree.api") },
               status: :unauthorized) && return
      end

      def not_found
        render(json: { error: I18n.t(:resource_not_found, scope: "spree.api") },
               status: :not_found) && return
      end
    end
  end
end
