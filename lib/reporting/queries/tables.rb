# frozen_string_literal: true

module Reporting
  module Queries
    module Tables
      def order_table
        Spree::Order.arel_table
      end

      def line_item_table
        Spree::LineItem.arel_table
      end

      def product_table
        Spree::Product.arel_table
      end

      def variant_table
        Spree::Variant.arel_table
      end

      def customer_table
        ::Customer.arel_table
      end

      def distributor_alias
        Enterprise.arel_table.alias(:order_distributor)
      end

      def supplier_alias
        Enterprise.arel_table.alias(:product_supplier)
      end

      # The producer is the first enterprise in the chain of linked variants, if
      # any, otherwise the variant's own enterprise. Mirrors Spree::Variant#producer,
      # but resolved as a correlated subquery so it can be used in report SQL.
      def producer_name_field
        Arel.sql(<<~SQL.squish)
          (
            SELECT enterprises.name FROM variant_links
            INNER JOIN spree_variants AS source_variant_for_producer
              ON source_variant_for_producer.id = variant_links.source_variant_id
            INNER JOIN enterprises
              ON enterprises.id = source_variant_for_producer.enterprise_id
            WHERE variant_links.target_variant_id = spree_variants.id
            ORDER BY source_variant_for_producer.id ASC
            LIMIT 1
          )
        SQL
      end

      def bill_address_alias
        Spree::Address.arel_table.alias(:bill_address)
      end

      def managed_orders_alias
        Spree::Order.arel_table.alias(:managed_orders)
      end

      def shipping_category_table
        Spree::ShippingCategory.arel_table
      end

      def shipping_method_table
        Spree::ShippingMethod.arel_table
      end

      def shipping_rate_table
        Spree::ShippingRate.arel_table
      end

      def shipment_table
        Spree::Shipment.arel_table
      end
    end
  end
end
