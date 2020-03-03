require 'open_food_network/spree_api_key_loader'
require 'open_food_network/referer_parser'
require 'open_food_network/permissions'

module Spree
  module Admin
    class ProductsController < ResourceController
      helper 'spree/products'
      include OpenFoodNetwork::SpreeApiKeyLoader
      include OrderCyclesHelper
      include EnterprisesHelper

      create.before :create_before
      update.before :update_before

      before_filter :load_data
      before_filter :load_form_data, only: [:index, :new, :create, :edit, :update]
      before_filter :load_spree_api_key, only: [:index, :variant_overrides]
      before_filter :strip_new_properties, only: [:create, :update]

      respond_override create: { html: {
        success: lambda {
          if params[:button] == "add_another"
            redirect_to new_admin_product_path
          else
            redirect_to admin_products_path
          end
        },
        failure: lambda {
          render :new
        }
      } }

      def new
        @object.shipping_category = DefaultShippingCategory.find_or_create
        super
      end

      def create
        delete_stock_params_and_set_after do
          super
        end
      rescue Paperclip::Errors::NotIdentifiedByImageMagickError
        invoke_callbacks(:create, :fails)
        @object.errors.add(:base, t('spree.admin.products.image_upload_error'))
        respond_with(@object)
      end

      def show
        session[:return_to] ||= request.referer
        redirect_to( action: :edit )
      end

      def index
        @current_user = spree_current_user
        @show_latest_import = params[:latest_import] || false
      end

      def update
        original_supplier_id = @product.supplier_id

        delete_stock_params_and_set_after do
          super
          if original_supplier_id != @product.supplier_id
            ExchangeVariantDeleter.new.delete(@product)
          end
        end
      end

      def bulk_update
        product_set = product_set_from_params(params)

        product_set.collection.each { |p| authorize! :update, p }

        if product_set.save
          redirect_to main_app.bulk_products_api_products_path( bulk_index_query(params) )
        elsif product_set.errors.present?
          render json: { errors: product_set.errors }, status: :bad_request
        else
          render nothing: true, status: :internal_server_error
        end
      end

      def clone
        @new = @product.duplicate

        flash[:success] = if @new.save
                            Spree.t('notice_messages.product_cloned')
                          else
                            Spree.t('notice_messages.product_not_cloned')
                          end

        redirect_to edit_admin_product_url(@new)
      end

      protected

      def find_resource
        Product.find_by_permalink!(params[:id])
      end

      def location_after_save
        spree.edit_admin_product_url(@product)
      end

      def load_data
        @taxons = Taxon.order(:name)
        @option_types = OptionType.order(:name)
        @tax_categories = TaxCategory.order(:name)
        @shipping_categories = ShippingCategory.order(:name)
      end

      def collection
        return @collection if @collection.present?

        params[:q] ||= {}
        params[:q][:deleted_at_null] ||= "1"

        params[:q][:s] ||= "name asc"
        @collection = Spree::Product
        @collection = @collection.with_deleted if params[:q].delete(:deleted_at_null).blank?
        # @search needs to be defined as this is passed to search_form_for
        @search = @collection.ransack(params[:q])
        @collection = @search.result.
          managed_by(spree_current_user).
          group_by_products_id.
          includes(product_includes).
          page(params[:page]).
          per(Spree::Config[:admin_products_per_page])

        if params[:q][:s].include?("master_default_price_amount")
          # PostgreSQL compatibility
          @collection = @collection.group("spree_prices.amount")
        end
        @collection
      end

      def create_before
        return if params[:product][:prototype_id].blank?

        @prototype = Spree::Prototype.find(params[:product][:prototype_id])
      end

      def update_before
        # We only reset the product properties if we're receiving a post from the form on that tab
        return unless params[:clear_product_properties]

        params[:product] ||= {}
      end

      def product_includes
        [{ variants: [:images, { option_values: :option_type }] },
         { master: [:images, :default_price] }]
      end

      def collection_actions
        [:index, :bulk_update]
      end

      private

      def product_set_from_params(params)
        collection_hash = Hash[products_params.each_with_index.map { |p, i| [i, p] }]
        Spree::ProductSet.new(collection_attributes: collection_hash)
      end

      def products_params
        params.require(:products).map do |product|
          product.permit(permitted_product_attributes)
        end
      end

      def permitted_resource_params
        return params[:product] if params[:product].empty?

        params.require(:product).permit(permitted_product_attributes)
      end

      def permitted_product_attributes
        [
          :id, :name, :description, :supplier_id, :price, :cost_price, :permalink,
          :variant_unit, :variant_unit_scale, :unit_value, :unit_description,
          :display_as, :variant_unit_name, :sku, :available_on,
          :taxon_ids, :primary_taxon_id, :tax_category_id, :shipping_category_id,
          :group_buy, :group_buy_unit_size,
          :meta_keywords, :meta_description, :notes,
          :inherits_properties,
          product_properties_attributes: [:id, :property_name, :value],
          variants_attributes: [:id, :sku, :on_hand, :price, :unit_value, :unit_description, :display_name, :display_as],
          images_attributes: [:attachment]
        ]
      end

      def bulk_index_query(params)
        params[:filters].to_h.merge(page: params[:page], per_page: params[:per_page])
      end

      def load_form_data
        @producers = OpenFoodNetwork::Permissions.new(spree_current_user).
          managed_product_enterprises.is_primary_producer.by_name
        @taxons = Spree::Taxon.order(:name)
        @import_dates = product_import_dates.uniq.to_json
      end

      def product_import_dates
        options = [{ id: '0', name: '' }]
        product_import_dates_query.collect(&:import_date).
          map { |i| options.push(id: i.to_date, name: i.to_date.to_formatted_s(:long)) }

        options
      end

      def product_import_dates_query
        Spree::Variant.
          select('DISTINCT spree_variants.import_date').
          joins(:product).
          where('spree_products.supplier_id IN (?)', editable_enterprises.collect(&:id)).
          where('spree_variants.import_date IS NOT NULL').
          where(spree_variants: { is_master: false }).
          where(spree_variants: { deleted_at: nil }).
          order('spree_variants.import_date DESC')
      end

      def strip_new_properties
        return if spree_current_user.admin? || params[:product][:product_properties_attributes].nil?

        names = Spree::Property.pluck(:name)
        params[:product][:product_properties_attributes].each do |key, property|
          unless names.include? property[:property_name]
            params[:product][:product_properties_attributes].delete key
          end
        end
      end

      def delete_stock_params_and_set_after
        on_demand = params[:product].delete(:on_demand)
        on_hand = params[:product].delete(:on_hand)

        yield

        set_stock_levels(@product, on_hand, on_demand) if @product.valid?
      end

      def set_stock_levels(product, on_hand, on_demand)
        variant = product_variant(product)

        begin
          variant.on_demand = on_demand if on_demand.present?
          variant.on_hand = on_hand.to_i if on_hand.present?
        rescue StandardError => e
          notify_bugsnag(e, product, variant)
          raise e
        end
      end

      def notify_bugsnag(error, product, variant)
        Bugsnag.notify(error) do |report|
          report.add_tab(:product, product.attributes)
          report.add_tab(:product_error, product.errors.first) unless product.valid?
          report.add_tab(:variant, variant.attributes)
          report.add_tab(:variant_error, variant.errors.first) unless variant.valid?
        end
      end

      def product_variant(product)
        if product.variants.any?
          product.variants.first
        else
          product.master
        end
      end

      def set_product_master_variant_price_to_zero
        @product.price = 0 if @product.price.nil?
      end
    end
  end
end
