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

      def bill_address_alias
        Spree::Address.arel_table.alias(:bill_address)
      end

      def managed_orders_alias
        Spree::Order.arel_table.alias(:managed_orders)
      end

      def shipping_category_table
        Spree::ShippingCategory.arel_table
      end
    end
  end
end
