# frozen_string_literal: true

class ProductsReflex < ApplicationReflex
  include Pagy::Backend

  before_reflex :init_filters_params, :init_pagination_params

  def fetch
    fetch_and_render_products
  end

  def change_per_page
    @per_page = element.value.to_i
    @page = 1

    fetch_and_render_products
  end

  def filter
    @page = 1

    fetch_and_render_products
  end

  def clear_search
    @search_term = nil
    @producer_id = nil
    @category_id = nil
    @page = 1

    fetch_and_render_products
  end

  def bulk_update
    product_set = product_set_from_params

    product_set.collection.each { |p| authorize! :update, p }
    @products = product_set.collection # use instance variable mainly for testing

    if product_set.save
      flash[:success] = I18n.t('admin.products_v3.bulk_update.success')
    elsif product_set.errors.present?
      @error_counts = { saved: product_set.saved_count, invalid: product_set.invalid.count }
    end

    render_products_form_with_flash
  end

  private

  def init_filters_params
    # params comes from the form
    # _params comes from the url
    # priority is given to params from the form (if present) over url params
    @search_term = params[:search_term] || params[:_search_term]
    @producer_id = params[:producer_id] || params[:_producer_id]
    @category_id = params[:category_id] || params[:_category_id]
  end

  def init_pagination_params
    # prority is given to element dataset (if present) over url params
    @page = element.dataset.page || params[:_page] || 1
    @per_page = element.dataset.perpage || params[:_per_page] || 15
  end

  def fetch_and_render_products
    fetch_products
    render_products
  end

  def render_products
    cable_ready.replace(
      selector: "#products-content",
      html: render(partial: "admin/products_v3/content",
                   locals: { products: @products, pagy: @pagy, search_term: @search_term,
                             producer_options: producers, producer_id: @producer_id,
                             category_options: categories, category_id: @category_id })
    ).broadcast

    cable_ready.replace_state(
      url: current_url,
    ).broadcast_later

    morph :nothing
  end

  def render_products_form_with_flash
    locals = { products: @products }
    locals[:error_counts] = @error_counts if @error_counts.present?
    locals[:flashes] = flash if flash.any?

    cable_ready.replace(
      selector: "#products-form",
      html: render(partial: "admin/products_v3/table", locals:)
    ).broadcast
    morph :nothing

    # dunno why this doesn't work.
    # morph "#products-form", render(partial: "admin/products_v3/table",
    #                locals: { products: products })
  end

  def producers
    producers = OpenFoodNetwork::Permissions.new(current_user)
      .managed_product_enterprises.is_primary_producer.by_name
    producers.map { |p| [p.name, p.id] }
  end

  def categories
    Spree::Taxon.order(:name).map { |c| [c.name, c.id] }
  end

  def fetch_products
    product_query = OpenFoodNetwork::Permissions.new(current_user)
      .editable_products.merge(product_scope).ransack(ransack_query).result
    @pagy, @products = pagy(product_query.order(:name), items: @per_page, page: @page,
                                                        size: [1, 2, 2, 1])
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
    query = {}
    query.merge!(supplier_id_in: @producer_id) if @producer_id.present?
    if @search_term.present?
      query.merge!(Spree::Variant::SEARCH_KEY => @search_term)
    end
    query.merge!(primary_taxon_id_in: @category_id) if @category_id.present?
    query
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
    # add params with _ to avoid conflicts with params from the form
    url.query += "_page=#{@page}"
    url.query += "&_per_page=#{@per_page}"
    url.query += "&_search_term=#{@search_term}" if @search_term.present?
    url.query += "&_producer_id=#{@producer_id}" if @producer_id.present?
    url.query += "&_category_id=#{@category_id}" if @category_id.present?
    url.to_s
  end

  # Similar to spree/admin/products_controller
  def product_set_from_params
    # Form field names:
    #   '[products][0][id]' (hidden field)
    #   '[products][0][name]'
    #   '[products][0][variants_attributes][0][id]' (hidden field)
    #   '[products][0][variants_attributes][0][display_name]'
    #
    # Resulting in params:
    #     "products" => {
    #       "0" =>  {
    #         "id" => "123"
    #         "name" => "Pommes",
    #         "variants_attributes" => {
    #           "0" => {
    #           "id" => "1234",
    #           "display_name" => "Large box",
    #         }
    #       }
    #     }
    collection_hash = products_bulk_params[:products]
      .transform_values { |product|
        # Convert variants_attributes form hash to an array if present
        product[:variants_attributes] &&= product[:variants_attributes].values
        product
      }.with_indifferent_access
    Sets::ProductSet.new(collection_attributes: collection_hash)
  end

  def products_bulk_params
    params.permit(products: ::PermittedAttributes::Product.attributes)
      .to_h.with_indifferent_access
  end
end
