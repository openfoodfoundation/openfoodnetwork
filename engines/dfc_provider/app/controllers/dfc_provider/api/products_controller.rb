# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
module DfcProvider
  module Api
    class ProductsController < ::ActionController::Metal
      include ActionController::Head
      include AbstractController::Rendering
      include ActionController::Rendering
      include ActionController::Renderers::All
      include ActionController::MimeResponds
      include ActionController::ImplicitRender
      include AbstractController::Callbacks
      # To access 'base_url' helper
      include ActionController::UrlFor
      include Rails.application.routes.url_helpers

      before_filter :check_authorization,
                    :check_user,
                    :check_enterprise

      respond_to :json

      def index
        products = @enterprise.
          inventory_variants.
          includes(:product, :inventory_items)

        products_json = ::DfcProvider::ProductSerializer.
          new(products, base_url).
          serialized_json

        render json: products_json
      end

      private

      def check_enterprise
        @enterprise = @user.enterprises.first

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
