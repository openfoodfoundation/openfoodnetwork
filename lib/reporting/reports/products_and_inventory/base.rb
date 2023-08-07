# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'

module Reporting
  module Reports
    module ProductsAndInventory
      class Base < ReportTemplate
        def query_result
          filter(child_variants)
        end

        # rubocop:disable Metrics/AbcSize
        def columns
          {
            supplier: proc { |variant| variant.product.supplier.name },
            producer_suburb: proc { |variant| variant.product.supplier.address.city },
            product: proc { |variant| variant.product.name },
            product_properties: proc { |v| v.product.properties.map(&:name).join(", ") },
            taxons: proc { |variant| variant.product.primary_taxon.name },
            variant_value: proc { |variant| variant.full_name },
            price: proc { |variant| variant.price },
            group_buy_unit_quantity: proc { |variant| variant.product.group_buy_unit_size },
            amount: proc { |_variant| "" },
            sku: proc { |variant| variant.sku.presence || variant.product.sku },
          }
        end
        # rubocop:enable Metrics/AbcSize

        def filter(variants)
          filter_on_hand filter_to_distributor filter_to_order_cycle filter_to_supplier variants
        end

        def child_variants
          Spree::Variant.
            joins(:product).
            merge(visible_products).
            order('spree_products.name')
        end

        private

        def report_type
          params[:report_subtype]
        end

        def visible_products
          @visible_products ||= permissions.visible_products
        end

        def permissions
          @permissions ||= OpenFoodNetwork::Permissions.new(@user)
        end

        # Using the `in_stock?` method allows overrides by distributors.
        def filter_on_hand(variants)
          variants.select(&:in_stock?)
        end

        def filter_to_supplier(variants)
          if params[:supplier_id].to_i > 0
            variants.where("spree_products.supplier_id = ?", params[:supplier_id])
          else
            variants
          end
        end

        def filter_to_distributor(variants)
          if params[:distributor_id].to_i > 0
            distributor = Enterprise.find params[:distributor_id]
            scoper = OpenFoodNetwork::ScopeVariantToHub.new(distributor)
            variants.in_distributor(distributor).each { |v| scoper.scope(v) }
          else
            variants
          end
        end

        def filter_to_order_cycle(variants)
          if params[:order_cycle_id].to_i > 0
            order_cycle = OrderCycle.find params[:order_cycle_id]
            variant_ids = Exchange.in_order_cycle(order_cycle).
              joins("INNER JOIN exchange_variants ON exchanges.id = exchange_variants.exchange_id").
              select("DISTINCT exchange_variants.variant_id")

            variants.where("spree_variants.id IN (#{variant_ids.to_sql})")
          else
            variants
          end
        end
      end
    end
  end
end
