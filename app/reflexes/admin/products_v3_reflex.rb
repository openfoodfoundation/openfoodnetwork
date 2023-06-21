# frozen_string_literal: true

module Admin
  class ProductsV3Reflex < ApplicationReflex
    include Pagy::Backend

    before_reflex :fetch_products, only: [:fetch]

    def fetch
      cable_ready.replace(
        selector: "#products-content",
        html: render(partial: "admin/products_v3/content",
                     locals: { products: @products, pagy: @pagy })
      ).broadcast

      morph :nothing
    end

    private

    # copied from ProductsTableComponent
    def fetch_products
      product_query = OpenFoodNetwork::Permissions.new(current_user)
        .editable_products.merge(product_scope)
      @pagy, @products = pagy(product_query.order(:name), items: 50, page: params[:page])
    end

    def product_scope
      scope = if current_user.has_spree_role?("admin") || current_user.enterprises.present?
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
