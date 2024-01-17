# frozen_string_literal: true

# Controller used to provide the SuppliedProducts API for the DFC application
# SuppliedProducts are products that are managed by an enterprise.
module DfcProvider
  class SuppliedProductsController < DfcProvider::ApplicationController
    before_action :check_enterprise
    rescue_from JSON::LD::JsonLdError::LoadingDocumentFailed, with: -> do
      head :bad_request
    end

    def create
      supplied_product = import&.first

      return head :bad_request unless supplied_product

      variant = SuppliedProductBuilder.import_variant(supplied_product)
      product = variant.product

      if product.new_record?
        product.supplier = current_enterprise
        product.save!
      end

      if variant.new_record?
        variant.save!
      end

      supplied_product = SuppliedProductBuilder.supplied_product(variant)
      render json: DfcIo.export(supplied_product)
    end

    def show
      product = SuppliedProductBuilder.supplied_product(variant)
      render json: DfcIo.export(product)
    end

    def update
      supplied_product = import&.first

      return head :bad_request unless supplied_product

      SuppliedProductBuilder.apply(supplied_product, variant)

      variant.product.save!
      variant.save!
    end

    private

    def variant
      @variant ||= current_enterprise.supplied_variants.find(params[:id])
    end
  end
end
