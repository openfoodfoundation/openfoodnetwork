# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
module DfcProvider
  module Api
    class ProductsController < BaseController
      # To access 'base_url' helper
      include Rails.application.routes.url_helpers

      def index
        render json: @user, serializer: DfcProvider::PersonSerializer
      end

      def show
        @variant = Spree::Variant.joins(product: :supplier)
                                 .where('enterprises.id' => @enterprise.id)
                                 .find(params[:id])

        render json: @variant, serializer: DfcProvider::CatalogItemSerializer
      end
    end
  end
end
