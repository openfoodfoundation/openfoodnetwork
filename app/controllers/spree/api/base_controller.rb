require_dependency 'spree/api/controller_setup'

module Spree
  module Api
    class BaseController < ActionController::Metal
      include Spree::Api::ControllerSetup
      include Spree::Core::ControllerHelpers::SSL
      include ::ActionController::Head

      respond_to :json

      attr_accessor :current_api_user

      before_filter :set_content_type
      before_filter :authenticate_user
      after_filter  :set_jsonp_format

      rescue_from Exception, :with => :error_during_processing
      rescue_from CanCan::AccessDenied, :with => :unauthorized
      rescue_from ActiveRecord::RecordNotFound, :with => :not_found

      helper Spree::Api::ApiHelpers

      ssl_allowed

      def set_jsonp_format
        if params[:callback] && request.get?
          self.response_body = "#{params[:callback]}(#{response_body})"
          headers["Content-Type"] = 'application/javascript'
        end
      end

      private

      def set_content_type
        content_type = case params[:format]
                       when "json"
                         "application/json"
                       when "xml"
                         "text/xml"
                       end
        headers["Content-Type"] = content_type
      end

      def authenticate_user
        return if @current_api_user

        if api_key.blank?
          # An anonymous user
          @current_api_user = Spree.user_class.new
          return
        end

        unless @current_api_user = Spree.user_class.find_by_spree_api_key(api_key.to_s)
          invalid_api_key
        end
      end

      def error_during_processing(exception)
        render(text: { exception: exception.message }.to_json,
               status: :unprocessable_entity) && return
      end

      def current_ability
        Spree::Ability.new(current_api_user)
      end

      def api_key
        request.headers["X-Spree-Token"] || params[:token]
      end
      helper_method :api_key
    end
  end
end
