# frozen_string_literal: true

class ProductsReflex < ApplicationReflex
  include Pagy::Backend

  def fetch
    @page ||= element.dataset.page || 1
    @per_page ||= element.dataset.perpage || 15
    @search_term ||= element.dataset.searchterm || ""

    fetch_products

    render_products
  end

  def change_per_page
    @per_page = element.value.to_i
    @page = 1

    fetch
  end

  def filter
    @per_page = params[:per_page]
    @page = 1
    @search_term = params[:search_term]

    fetch_products
    render_products
  end

  private

  def render_products
    cable_ready.replace(
      selector: "#products-content",
      html: render(partial: "admin/products_v3/content",
                   locals: { products: @products, pagy: @pagy, search_term: @search_term })
    ).broadcast

    cable_ready.replace_state(
      url: current_url,
    ).broadcast_later

    morph :nothing
  end

  # copied from ProductsTableComponent
  def fetch_products
    product_query = OpenFoodNetwork::Permissions.new(current_user)
      .editable_products.merge(product_scope).ransack(ransack_query).result
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

  def ransack_query
    query = { s: "name desc" }
    query.merge({ name_cont: @search_term }) if @search_term.present?
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

  def current_url
    url = URI(request.original_url)
    url.query = url.query.present? ? "#{url.query}&" : ""
    url.query += "page=#{@page}&per_page=#{@per_page}"
    url.to_s
  end
end
