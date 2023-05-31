# frozen_string_literal: true

# Controller used to provide the SuppliedProducts API for the DFC application
# SuppliedProducts are products that are managed by an enterprise.
module DfcProvider
  class SuppliedProductsController < DfcProvider::BaseController
    before_action :check_enterprise

    def show
      product = DfcBuilder.supplied_product(variant)
      render json: DfcLoader.connector.export(product)
    end

    def update
      dfc_request = JSON.parse(request.body.read)
      return unless dfc_request.key?("dfc-b:description")

      variant.product.update!(
        description: dfc_request["dfc-b:description"],
      )

      # This input is DFC v1.6 currently sent by the DFC Prototype.
      variant.update!(
        unit_value: dfc_request["dfc-b:quantity"],
      )
    end

    private

    def variant
      @variant ||=
        VariantFetcher.new(current_enterprise).scope.find(params[:id])
    end
  end
end
