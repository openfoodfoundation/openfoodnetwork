# frozen_string_literal: true

# Show Spree::Product as SuppliedProduct with variants.
module DfcProvider
  class ProductGroupsController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def show
      spree_product = current_enterprise.supplied_products.find(params[:id])
      product = ProductGroupBuilder.product_group(spree_product)
      render json: DfcIo.export(product)
    end
  end
end
