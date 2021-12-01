# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
module DfcProvider
  module Api
    module V0
      class BaseController < ::Api::V0::BaseController
        # Skip the authorization check from the main app
        skip_authorization_check

        before_action :check_authorization_with_access_token

        respond_to :json

        def show; end

        private

        def check_authorization_with_access_token
          return if access_token.present? && current_user.present?

          unauthorized
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
          @current_user ||= authorization_control.safe_process
        end

        def access_token
          request.headers['Authorization'].to_s.split(' ').last
        end

        def authorization_control
          DfcProvider::AuthorizationControl.new(access_token)
        end
      end
    end
  end
end
