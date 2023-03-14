# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
module DfcProvider
  class BaseController < ActionController::Base
    protect_from_forgery with: :null_session

    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    before_action :check_authorization

    respond_to :json

    private

    def check_authorization
      head :unauthorized if current_user.nil?
    end

    def check_enterprise
      return if current_enterprise.present?

      not_found
    end

    def current_enterprise
      @current_enterprise ||=
        case params[enterprise_id_param_name]
        when 'default'
          current_user.enterprises.first!
        else
          current_user.enterprises.find(params[enterprise_id_param_name])
        end
    end

    def enterprise_id_param_name
      :enterprise_id
    end

    def current_user
      @current_user ||= authorization_control.user
    end

    def authorization_control
      AuthorizationControl.new(request)
    end

    def not_found
      head :not_found
    end
  end
end
