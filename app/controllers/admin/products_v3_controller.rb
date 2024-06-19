# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Admin
  class ProductsV3Controller < Spree::Admin::BaseController
    helper ProductsHelper

    before_action :init_filters_params
    before_action :init_pagination_params

    def index
      fetch_products
      render "index", locals: { producers:, categories:, tax_category_options:, flash: }
    end

    def bulk_update
      product_set = product_set_from_params

      product_set.collection.each { |p| authorize! :update, p }
      @products = product_set.collection # use instance variable mainly for testing

      if product_set.save
        flash[:success] = I18n.t('admin.products_v3.bulk_update.success')
        redirect_to [:index,
                     { page: @page, per_page: @per_page, search_term: @search_term,
                       producer_id: @producer_id, category_id: @category_id }]
      elsif product_set.errors.present?
        @error_counts = { saved: product_set.saved_count, invalid: product_set.invalid.count }

        render "index", status: :unprocessable_entity,
                        locals: { producers:, categories:, tax_category_options:, flash: }
      end
    end

    def destroy
      @record = ProductScopeQuery.new(
        spree_current_user,
        { id: params[:id] }
      ).find_product

      @record.destroyed_by = spree_current_user
      status = :ok

      if @record.destroy
        flash.now[:success] = t('.delete_product.success')
      else
        flash.now[:error] = t('.delete_product.error')
        status = :internal_server_error
      end

      respond_with do |format|
        format.turbo_stream { render :destroy_product_variant, status: }
      end
    end

    def destroy_variant
      @record = Spree::Variant.active.find(params[:id])
      authorize! :delete, @record

      status = :ok
      if VariantDeleter.new.delete(@record)
        flash.now[:success] = t('.delete_variant.success')
      else
        flash.now[:error] = t('.delete_variant.error')
        status = :internal_server_error
      end

      respond_with do |format|
        format.turbo_stream { render :destroy_product_variant, status: }
      end
    end

    def index_url(params)
      "/admin/products?#{params.to_query}" # todo: fix routing so this can be automaticly generated
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
      @page = params[:page].presence || 1
      @per_page = params[:per_page].presence || 15
      @q = params.permit(q: {})[:q] || { s: 'name asc' }
    end

    def producers
      producers = OpenFoodNetwork::Permissions.new(spree_current_user)
        .managed_product_enterprises.is_primary_producer.by_name
      producers.map { |p| [p.name, p.id] }
    end

    def categories
      Spree::Taxon.order(:name).map { |c| [c.name, c.id] }
    end

    def tax_category_options
      Spree::TaxCategory.order(:name).pluck(:name, :id)
    end

    def fetch_products
      product_query = OpenFoodNetwork::Permissions.new(spree_current_user)
        .editable_products.merge(product_scope).ransack(ransack_query).result
      @pagy, @products = pagy(product_query.order(:name), items: @per_page, page: @page,
                                                          size: [1, 2, 2, 1])
    end

    def product_scope
      user = spree_current_user
      scope = if user.has_spree_role?("admin") || user.enterprises.present?
                Spree::Product
              else
                Spree::Product.active
              end

      scope.includes(product_query_includes).distinct
    end

    def ransack_query
      query = {}
      query.merge!(supplier_id_in: @producer_id) if @producer_id.present?
      if @search_term.present?
        query.merge!(Spree::Variant::SEARCH_KEY => @search_term)
      end
      query.merge!(variants_primary_taxon_id_in: @category_id) if @category_id.present?
      query.merge!(@q) if @q

      query
    end

    # Optimise by pre-loading required columns
    def product_query_includes
      [
        :image,
        :supplier,
        { variants: [
          :default_price,
          :primary_taxon,
          :product,
          :stock_items,
          :tax_category,
        ] },
      ]
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
end
# rubocop:enable Metrics/ClassLength
