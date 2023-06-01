# frozen_string_literal: true

module Reporting
  module Queries
    module Joins
      def joins_order
        reflect query.join(association(Spree::LineItem, :order))
      end

      def joins_order_distributor
        reflect query.join(association(Spree::Order, :distributor, distributor_alias))
      end

      def joins_variant
        reflect query.join(association(Spree::LineItem, :variant))
      end

      def joins_variant_product
        reflect query.join(association(Spree::Variant, :product))
      end

      def joins_product_supplier
        reflect query.join(association(Spree::Product, :supplier, supplier_alias))
      end

      def joins_product_shipping_category
        reflect query.join(association(Spree::Product, :shipping_category))
      end

      def joins_order_and_distributor
        reflect query.
          join(association(Spree::LineItem, :order)).
          join(association(Spree::Order, :distributor, distributor_alias))
      end

      def joins_order_customer
        reflect query.join(association(Spree::Order, :customer))
      end

      def joins_order_bill_address
        reflect query.join(association(Spree::Order, :bill_address, bill_address_alias))
      end
    end
  end
end
