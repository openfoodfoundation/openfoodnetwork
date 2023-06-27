# frozen_string_literal: true

class ProductsV3Reflex < ApplicationReflex
  include Pagy::Backend

  def fetch
    @page = element.dataset.page || 1
    @per_page ||= 15

    fetch_products

    render_products
  end

  def change_per_page
    @per_page = element.value.to_i
    @page = 1

    fetch_products

    render_products
  end

  private

  def render_products
    cable_ready.replace(
      selector: "#products-content",
      html: render(partial: "admin/products_v3/content",
                   locals: { products: @products, pagy: @pagy })
    ).broadcast

    morph :nothing
  end

  # copied from ProductsTableComponent
  def fetch_products
    product_query = OpenFoodNetwork::Permissions.new(current_user)
      .editable_products.merge(product_scope)
    @pagy, @products = pagy(product_query.order(:name), items: @per_page, page: @page)
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
