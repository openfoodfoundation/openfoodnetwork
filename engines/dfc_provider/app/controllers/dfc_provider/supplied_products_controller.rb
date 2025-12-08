# frozen_string_literal: true

# Controller used to provide the SuppliedProducts API for the DFC application
# SuppliedProducts are products that are managed by an enterprise.
module DfcProvider
  class SuppliedProductsController < DfcProvider::ApplicationController
    before_action :check_enterprise, except: :index
    rescue_from JSON::LD::JsonLdError::LoadingDocumentFailed, with: -> do
      head :bad_request
    end

    def index
      # WARNING!
      #
      # For DFC platforms accessing this with scoped permissions:
      # We rely on the ReadEnterprise scope to list enterprises and
      # assume that the ReadProducts scope has been granted as well.
      #
      # This will be correct for the first iteration of the DFC Permissions
      # module but needs to be revised later.
      enterprises = current_user.enterprises.map do |enterprise|
        EnterpriseBuilder.enterprise(enterprise)
      end
      catalog_items = enterprises.flat_map(&:catalogItems)

      render json: DfcIo.export(
        *catalog_items,
        *catalog_items.map(&:product),
        *catalog_items.map(&:product).flat_map(&:isVariantOf),
        *catalog_items.flat_map(&:offers),
      )
    end

    def show
      product = SuppliedProductBuilder.supplied_product(variant)
      render json: DfcIo.export(product)
    end

    def create
      supplied_product = import&.first

      return head :bad_request unless supplied_product

      variant = SuppliedProductImporter.store_product(
        supplied_product,
        current_enterprise,
      )

      supplied_product = SuppliedProductBuilder.supplied_product(variant)
      render json: DfcIo.export(supplied_product)
    end

    def update
      supplied_product = import&.first

      return head :bad_request unless supplied_product

      SuppliedProductImporter.update_product(supplied_product, variant)
    end

    private

    def variant
      @variant ||= current_enterprise.supplied_variants.find(params[:id])
    end
  end
end
