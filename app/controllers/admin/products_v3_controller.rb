# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Admin
  class ProductsV3Controller < Spree::Admin::BaseController
    helper ProductsHelper

    before_action :init_filters_params
    before_action :init_pagination_params
    before_action :init_none_tag

    def index
      fetch_products
      render "index",
             locals: { producer_options:, categories:, tax_category_options:, available_tags:,
                       flash:, allowed_producers: }

      session[:products_return_to_url] = request.url
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
                        locals: {
                          producer_options:, categories:, tax_category_options:, available_tags:,
                          allowed_producers:, flash:
                        }
      end
    end

    def destroy
      @record = ProductScopeQuery.new(
        spree_current_user,
        { id: params[:id] }
      ).find_product

      authorize! :delete, @record

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

    def clone
      product = Spree::Product.find(params[:id])
      authorize! :clone, product

      status = :ok

      begin
        cloned_product = product.duplicate
        flash.now[:success] = t('.success')

        product_index = "-#{cloned_product.id}"
      rescue ActiveRecord::ActiveRecordError => e
        flash.now[:error] = clone_error_message(e)
        status = :unprocessable_entity
        product_index = "-1" # Create a unique enough index
      end

      respond_with do |format|
        format.turbo_stream {
          render :clone, status:,
                         locals: { product:, cloned_product:, product_index:, producer_options:,
                                   category_options: categories, tax_category_options:,
                                   allowed_producers: }
        }
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
      @tags = params[:tags_name_in] || params[:_tags_name_in]
    end

    def init_pagination_params
      # prority is given to element dataset (if present) over url params
      @page = params[:page].presence || 1
      @per_page = params[:per_page].presence || 15
      @q = params.permit(q: {})[:q] || { s: 'name asc' }

      # Transform on_hand sorting to properly handle On-Demand products:
      #   - On-Demand products should ignore on_hand completely and sort alphabetically.
      #   - Non-On-Demand products should continue sorting by on_hand as usual.
      if @q[:s] == 'on_hand asc'
        @q[:s] = [
          'backorderable_priority asc',
          'backorderable_name asc',
          @q[:s]
        ]
      elsif @q[:s] == 'on_hand desc'
        @q[:s] = [
          'backorderable_priority desc',
          'backorderable_name asc',
          @q[:s]
        ]
      end
    end

    def allowed_producers
      OpenFoodNetwork::Permissions.new(spree_current_user)
        .managed_product_enterprises.is_primary_producer.by_name
    end

    def producer_options
      allowed_producers.map { |p| [p.name, p.id] }
    end

    def categories
      Spree::Taxon.order(:name).map { |c| [c.name, c.id] }
    end

    def tax_category_options
      Spree::TaxCategory.order(:name).pluck(:name, :id)
    end

    def available_tags
      variants = Spree::Variant.where(
        product: OpenFoodNetwork::Permissions.new(spree_current_user)
          .editable_products
          .merge(product_scope)
      )

      ActsAsTaggableOn::Tag.joins(:taggings).where(
        taggings: { taggable_type: "Spree::Variant", taggable_id: variants }
      ).distinct.order(:name).pluck(:name)
    end

    def fetch_products
      product_query = OpenFoodNetwork::Permissions.new(spree_current_user)
        .editable_products.merge(product_scope_with_includes).ransack(ransack_query).result

      product_query = apply_tags_filter(product_query)

      # Postgres requires ORDER BY expressions to appear in the SELECT list when using DISTINCT.
      # When the current ransack sort uses the computed stock columns, include them in the select
      # so the generated COUNT/DISTINCT query is valid.
      sort_columns = Array(@q && @q[:s]).flatten
      if sort_columns.any? { |s|
           s.to_s.include?('on_hand') || s.to_s.include?('backorderable_priority')
         }

        product_query = product_query.select(
          Arel.sql('spree_products.*'),
          Spree::Product.backorderable_priority_sql,
          Spree::Product.backorderable_name_sql,
          Spree::Product.on_hand_sql
        )
      end

      @pagy, @products = pagy(
        product_query.order(:name),
        limit: @per_page,
        page: @page,
        size: [1, 2, 2, 1]
      )
    end

    def product_scope
      user = spree_current_user
      scope = if user.admin? || user.enterprises.present?
                Spree::Product
              else
                Spree::Product.active
              end

      scope.distinct
    end

    def product_scope_with_includes
      product_scope.includes(product_query_includes)
    end

    def ransack_query
      query = {}
      query.merge!(variants_supplier_id_in: @producer_id) if @producer_id.present?
      if @search_term.present?
        query.merge!(Spree::Variant::SEARCH_KEY => @search_term)
      end
      query.merge!(variants_primary_taxon_id_in: @category_id) if @category_id.present?
      query.merge!(@q) if @q

      query
    end

    # Apply tags filter with OR logic:
    # - Products with variants having selected tags
    # - OR products with variants having no tags (when "None" is selected)
    #
    # Note: This cannot be implemented using Ransack because Ransack applies
    # AND semantics across associations and cannot express OR logic that combines
    # the presence and absence of the same associated records.
    def apply_tags_filter(base_query)
      return base_query if @tags.blank?

      tag_names = Array(@tags).dup
      has_none_tag = (tag_names.delete(@none_tag_value) == @none_tag_value)

      queries = []

      if tag_names.any?
        # Products with at least one variant having one of the selected tags
        tagged_product_ids = Spree::Variant
          .joins(taggings: :tag)
          .where(tags: { name: tag_names })
          .select(:product_id)

        queries << base_query.where(id: tagged_product_ids)
      end

      if has_none_tag
        # Products where no variants have any tags
        tagged_product_ids = Spree::Variant
          .joins(:taggings)
          .select(:product_id)

        queries << base_query.where.not(id: tagged_product_ids)
      end

      return base_query if queries.empty?

      # Combine queries using ActiveRecord's or method
      queries.reduce { |combined, query| combined.or(query) }
    end

    # Optimise by pre-loading required columns
    def product_query_includes
      [
        :image,
        { variants: [
          :default_price,
          :primary_taxon,
          :product,
          :stock_items,
          :tax_category,
          :supplier,
          :taggings,
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

    def clone_error_message(error)
      case error
      when ActiveRecord::RecordInvalid
        error.record.errors.full_messages.to_sentence
      else
        t('.error')
      end
    end

    def init_none_tag
      @none_tag_value = '""'
    end
  end
end
# rubocop:enable Metrics/ClassLength
