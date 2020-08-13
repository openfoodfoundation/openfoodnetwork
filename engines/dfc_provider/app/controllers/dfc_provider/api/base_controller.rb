# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
module DfcProvider
  module Api
    class BaseController < ::ActionController::Base
      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      before_filter :check_authorization,
                    :check_user,
                    :check_enterprise

      respond_to :json

      private

      def check_authorization
        return if access_token.present?

        head :unprocessable_entity
      end

      def check_user
        @user = authorization_control.process

        return if @user.present?

        head :unauthorized
      end

      def check_enterprise
        @enterprise =
          if params[:enterprise_id] == 'default'
            @user.enterprises.first!
          else
            @user.enterprises.find(params[:enterprise_id])
          end
      end

      def access_token
        request.headers['Authorization'].to_s.split(' ').last
      end

      def authorization_control
        DfcProvider::AuthorizationControl.new(access_token)
      end

      def not_found
        head :not_found
      end
    end
  end
end
