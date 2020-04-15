# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
module Api
  module DfcProvider
    class ProductsController < Api::BaseController
      before_filter :set_enterprise

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

      def set_enterprise
        @enterprise = ::Enterprise.find(params[:enterprise_id])
      end

      def base_url
        "#{root_url}api/dfc_provider"
      end
    end
  end
end
