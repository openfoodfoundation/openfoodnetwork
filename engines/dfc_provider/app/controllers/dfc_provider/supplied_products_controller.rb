# frozen_string_literal: true

require "data_food_consortium/connector/connector"

# Controller used to provide the SuppliedProducts API for the DFC application
# SuppliedProducts are products that are managed by an enterprise.
module DfcProvider
  class SuppliedProductsController < DfcProvider::BaseController
    before_action :check_enterprise
    rescue_from JSON::LD::JsonLdError::LoadingDocumentFailed, with: -> do
      head :bad_request
    end

    def create
      supplied_product = import&.first

      return head :bad_request unless supplied_product

      product = SuppliedProductBuilder.import(supplied_product)
      product.supplier = current_enterprise
      product.save!

      supplied_product = SuppliedProductBuilder.supplied_product(
        product.variants.first
      )
      render json: DfcIo.export(supplied_product)
    end

    def show
      product = SuppliedProductBuilder.supplied_product(variant)
      render json: DfcIo.export(product)
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

    def import
      DfcLoader.connector.import(request.body)
    end

    def variant
      @variant ||=
        VariantFetcher.new(current_enterprise).scope.find(params[:id])
    end
  end
end
