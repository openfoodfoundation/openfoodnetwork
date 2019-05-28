# Base controller for OFN's API
# Includes the minimum machinery required by ActiveModelSerializers
module Api
  class BaseController < Spree::Api::BaseController
    # Need to include these because Spree::Api::BaseContoller inherits
    # from ActionController::Metal rather than ActionController::Base
    # and they are required by ActiveModelSerializers
    include ActionController::Serialization
    include ActionController::UrlFor
    include Rails.application.routes.url_helpers
    use_renderers :json
    check_authorization

    def respond_with_conflict(json_hash)
      render json: json_hash, status: :conflict
    end

    private

    # Use logged in user (spree_current_user) for API authentication (current_api_user)
    def authenticate_user
      @current_api_user = try_spree_current_user
      super
    end

    # Allows API access without authentication, but only for OFN controllers which inherit
    # from Api::BaseController. @current_api_user will now initialize an empty Spree::User
    # unless one is present. We now also apply devise's `check_authorization`. See here for
    # details: https://github.com/CanCanCommunity/cancancan/wiki/Ensure-Authorization
    def requires_authentication?
      false
    end
  end
end
