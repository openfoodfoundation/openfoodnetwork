# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
module DfcProvider
  module Api
    class ProductsController < ::ActionController::Base
      # To access 'base_url' helper
      include Rails.application.routes.url_helpers

      before_filter :check_authorization,
                    :check_user,
                    :check_enterprise

      respond_to :json

      def index
        render json: serialized_data_for(@user)
      end

      private

      def check_enterprise
        @enterprise =
          if params[:enterprise_id] == 'default'
            @user.enterprises.first
          else
            @user.enterprises.where(id: params[:enterprise_id]).first
          end

        return if @enterprise.present?

        head :not_found
      end

      def check_authorization
        return if access_token.present?

        head :unprocessable_entity
      end

      def check_user
        @user = authorization_control.process

        return if @user.present?

        head :unauthorized
      end

      def access_token
        request.headers['Authorization'].to_s.split(' ').last
      end

      def authorization_control
        DfcProvider::AuthorizationControl.new(access_token)
      end

      def serialized_data_for(user)
        {
          "@context" =>
          {
            "dfc" => "http://datafoodconsortium.org/ontologies/DFC_FullModel.owl#",
            "@base" => "#{root_url}api/dfc_provider"
          }
        }.merge(DfcProvider::PersonSerializer.new(user).serialized_data)
      end
    end
  end
end
