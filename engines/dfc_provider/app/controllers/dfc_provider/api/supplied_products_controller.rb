# frozen_string_literal: true

# Controller used to provide the SuppliedProducts API for the DFC application
module DfcProvider
  module Api
    class SuppliedProductsController < BaseController
      def show
        @product = @enterprise.supplied_products.find(params[:id])

        render json: @product, serializer: DfcProvider::SuppliedProductSerializer
      end
    end
  end
end
