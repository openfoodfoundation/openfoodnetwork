# frozen_string_literal: true

module Admin
  class ProductsV3Controller < Spree::Admin::BaseController
    before_action :fetch_products

    def index; end

    # copied from ProductsTableComponent
    def fetch_products
      product_query = OpenFoodNetwork::Permissions.new(spree_current_user)
        .editable_products.merge(product_scope)
      @products = product_query.order(:name).limit(50)
    end

    def product_scope
      scope = if spree_current_user.has_spree_role?("admin") ||
                 spree_current_user.enterprises.present?
                Spree::Product
              else
                Spree::Product.active
              end

      scope.includes(product_query_includes)
    end

    def product_query_includes
      # TODO: add other fielsd used in columns? (eg supplier: [:name])
      [
        master: [:images],
        variants: [
          :default_price,
          :stock_locations,
          :stock_items,
          :variant_overrides
        ]
      ]
    end
  end
end
