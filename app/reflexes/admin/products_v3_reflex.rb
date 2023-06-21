# frozen_string_literal: true

module Admin
  class ProductsV3Reflex < ApplicationReflex
    include Pagy::Backend

    def fetch
      fetch_products(element.dataset.page || 1)

      cable_ready.replace(
        selector: "#products-content",
        html: render(partial: "admin/products_v3/content",
                     locals: { products: @products, pagy: @pagy })
      ).broadcast

      morph :nothing
    end

    private

    # copied from ProductsTableComponent
    def fetch_products(page)
      product_query = OpenFoodNetwork::Permissions.new(current_user)
        .editable_products.merge(product_scope)
      @pagy, @products = pagy(product_query.order(:name), items: 15, page:)
    end

    def product_scope
      scope = if current_user.has_spree_role?("admin") || current_user.enterprises.present?
                Spree::Product
              else
                Spree::Product.active
              end

      scope.includes(product_query_includes)
    end

    # Optimise by pre-loading required columns
    def product_query_includes
      # TODO: add other fields used in columns? (eg supplier: [:name])
      [
        # variants: [
        #   :default_price,
        #   :stock_locations,
        #   :stock_items,
        #   :variant_overrides
        # ]
      ]
    end
  end
end
