# frozen_string_literal: true

# Show Spree::Product as SuppliedProduct with variants.
module DfcProvider
  class ProductGroupsController < DfcProvider::ApplicationController
    def show
      spree_product = permissions.visible_products.find(params[:id])
      product = ProductGroupBuilder.product_group(spree_product)
      render json: DfcIo.export(product)
    end

    private

    def permissions
      OpenFoodNetwork::Permissions.new(current_user)
    end
  end
end
