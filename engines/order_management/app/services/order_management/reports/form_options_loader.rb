# frozen_string_literal: true

module OrderManagement
  module Reports
    class FormOptionsLoader
      def initialize(current_user)
        @current_user = current_user
      end

      def distributors
        Enterprise.is_distributor.managed_by(current_user)
      end

      def suppliers
        my_suppliers = Enterprise.is_primary_producer.managed_by(current_user)

        my_suppliers | suppliers_of_distributed_products
      end

      def order_cycles
        OrderCycle.
          active_or_complete.
          visible_by(current_user).
          order('orders_close_at DESC')
      end

      private

      attr_reader :current_user

      def suppliers_of_distributed_products
        supplier_ids = Spree::Product.in_distributors(distributors.select('enterprises.id')).
          select('spree_products.supplier_id')

        Enterprise.where(id: supplier_ids)
      end
    end
  end
end
