# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
module DfcProvider
  module Api
    class ProductsController < ::ActionController::Metal
      include Spree::Api::ControllerSetup

      # To access 'base_url' helper
      include ActionController::UrlFor
      include Rails.application.routes.url_helpers

      before_filter :check_authorization,
                    :check_enterprise,
                    :check_user,
                    :check_accessibility

      def index
        products = @enterprise.
          inventory_variants.
          includes(:product, :inventory_items)

        products_json = ::DfcProvider::ProductSerializer.
          new(@enterprise, products, base_url).
          serialized_json

        render json: products_json
      end

      private

      def check_enterprise
        @enterprise = ::Enterprise.where(id: params[:enterprise_id]).first

        return if @enterprise.present?

        head :not_found
      end

      def check_authorization
        return if access_token.present?

        head :unauthorized
      end

      def check_user
        @user = authorization_control.process

        return if @user.present?

        head :unprocessable_entity
      end

      def check_accessibility
        return if @enterprise.owner == @user

        head :forbidden
      end

      def base_url
        "#{root_url}api/dfc_provider"
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
