# Base controller for OFN's API
require_dependency 'spree/api/controller_setup'
require "spree/core/controller_helpers/ssl"
require "application_responder"

module Api
  class BaseController < ActionController::Metal
    include ActionController::StrongParameters
    include ActionController::RespondWith
    include Spree::Api::ControllerSetup
    include Spree::Core::ControllerHelpers::SSL
    include ::ActionController::Head

    respond_to :json

    attr_accessor :current_api_user

    before_action :set_content_type
    before_action :authenticate_user
    after_action  :set_jsonp_format

    rescue_from Exception, with: :error_during_processing
    rescue_from CanCan::AccessDenied, with: :unauthorized
    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    helper Spree::Api::ApiHelpers

    ssl_allowed

    # Include these because we inherit from ActionController::Metal
    #   rather than ActionController::Base and these are required for AMS
    include ActionController::Serialization
    include ActionController::UrlFor
    include Rails.application.routes.url_helpers

    use_renderers :json
    check_authorization

    def set_jsonp_format
      return unless params[:callback] && request.get?

      self.response_body = "#{params[:callback]}(#{response_body})"
      headers["Content-Type"] = 'application/javascript'
    end

    def respond_with_conflict(json_hash)
      render json: json_hash, status: :conflict
    end

    private

    # Use logged in user (spree_current_user) for API authentication (current_api_user)
    def authenticate_user
      return if @current_api_user = spree_current_user

      if api_key.blank?
        # An anonymous user
        @current_api_user = Spree.user_class.new
        return
      end

      return if @current_api_user = Spree.user_class.find_by(spree_api_key: api_key.to_s)

      invalid_api_key
    end

    def set_content_type
      content_type = case params[:format]
                     when "json"
                       "application/json"
                     when "xml"
                       "text/xml"
                     end
      headers["Content-Type"] = content_type
    end

    def error_during_processing(exception)
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
