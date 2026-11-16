# frozen_string_literal: true

module Api
  module V0
    class OrderCyclesController < Api::V0::BaseController
      include EnterprisesHelper
      include ApiActionCaching

      skip_authorization_check
      skip_before_action :authenticate_user, :ensure_api_key, only: [
        :taxons, :properties
      ]

      caches_action :taxons, :properties,
                    expires_in: CacheService::FILTERS_EXPIRY,
                    cache_path: proc { |controller| controller.request.url }

      def products
        return render_no_products unless order_cycle.open?

        products = ProductsRenderer.new(
          distributor,
          order_cycle,
          customer,
          search_params,
          inventory_enabled:,
          variant_tag_enabled:
        ).products_json

        render plain: products
      rescue ProductsRenderer::NoProducts
        render_no_products
      end

      def taxons
        taxons = Spree::Taxon.
          joins(:products).
          where(spree_products: { id: distributed_products }).
          select('DISTINCT spree_taxons.*')

        render plain: ActiveModel::ArraySerializer.new(
          sort_taxons(taxons), each_serializer: Api::TaxonSerializer
        ).to_json
      end

      def properties
        render plain: ActiveModel::ArraySerializer.new(
          sort_properties(product_properties), each_serializer: Api::PropertySerializer
        ).to_json
      end

      private

      # Sort first by shopfront_taxon_order if set, then alphabetically.
      def sort_taxons(taxons)
        return taxons.sort_by(&:name) unless preferred_taxon_order?

        ordered_ids = distributor.preferred_shopfront_taxon_order.split(',').map(&:to_i)
        taxons.sort_by { |taxon| [ordered_ids.index(taxon.id) || ordered_ids.length, taxon.name] }
      end

      def preferred_taxon_order?
        distributor.preferred_shopfront_product_sorting_method == "by_category" &&
          distributor.preferred_shopfront_taxon_order.present?
      end

      # Properties in shopfront_property_order come first, the others stay alphabetical.
      def sort_properties(properties)
        ordered_ids = distributor.preferred_shopfront_property_order.split(',').map(&:to_i)
        return properties if ordered_ids.empty?

        properties.sort_by.with_index do |property, index|
          [ordered_ids.index(property.id) || ordered_ids.length, index]
        end
      end

      def render_no_products
        render status: :not_found, json: {}
      end

      # Product properties and producer properties, as both are filtered with q[with_properties].
      def product_properties
        distributed_products_service.properties_relation.
          order(Arel.sql("LOWER(spree_properties.presentation)"))
      end

      def search_params
        params.slice :q, :page, :per_page
      end

      def distributor
        @distributor ||= Enterprise.find_by(id: params[:distributor])
      end

      def order_cycle
        @order_cycle ||= OrderCycle.find_by(id: params[:id])
      end

      def customer
        @current_api_user&.customer_of(distributor) || nil
      end

      def distributed_products
        distributed_products_service.products_relation.pluck(:id)
      end

      def distributed_products_service
        OrderCycles::DistributedProductsService.new(
          distributor, order_cycle, customer, inventory_enabled:, variant_tag_enabled:,
        )
      end

      def inventory_enabled
        OpenFoodNetwork::FeatureToggle.enabled?(:inventory, distributor)
      end

      def variant_tag_enabled
        OpenFoodNetwork::FeatureToggle.enabled?(:variant_tag, distributor)
      end
    end
  end
end
