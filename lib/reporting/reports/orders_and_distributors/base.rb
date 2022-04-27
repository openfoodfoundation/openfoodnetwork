# frozen_string_literal: true

module Reporting
  module Reports
    module OrdersAndDistributors
      class Base < ReportTemplate
        # rubocop:disable Metrics/AbcSize
        def columns
          {
            order_date: proc { |line_item| line_item.order.completed_at.strftime("%F %T") },
            order_id: proc { |line_item| line_item.order.id },
            customer_name: proc { |line_item| line_item.order.bill_address.full_name },
            customer_email: proc { |line_item| line_item.order.email },
            customer_phone: proc { |line_item| line_item.order.bill_address.phone },
            customer_city: proc { |line_item| line_item.order.bill_address.city },
            sku: proc { |line_item| line_item.product.sku },
            item_name: proc { |line_item| line_item.product.name },
            variant: proc { |line_item| line_item.options_text },
            quantity: proc { |line_item| line_item.quantity },
            max_quantity: proc { |line_item| line_item.max_quantity },
            cost: proc { |line_item| line_item.price * line_item.quantity },
            shipping_cost: proc { |line_item| line_item.distribution_fee },
            payment_method: proc { |li| li.order.payments.first&.payment_method&.name },
            distributor: proc { |line_item| line_item.order.distributor&.name },
            distributor_address: proc { |line_item| line_item.order.distributor.address.address1 },
            distributor_city: proc { |line_item| line_item.order.distributor.address.city },
            distributor_postcode: proc { |line_item| line_item.order.distributor.address.zipcode },
            shipping_method: proc { |line_item| line_item.order.shipping_method&.name },
            shipping_instructions: proc { |line_item| line_item.order.special_instructions }
          }
        end
        # rubocop:enable Metrics/AbcSize

        def search
          permissions.visible_orders.select("DISTINCT spree_orders.*").
            complete.not_state(:canceled).
            ransack(ransack_params)
        end

        def query_result
          orders = search.result
          # Mask non editable order details
          editable_orders_ids = permissions.editable_orders.select(&:id).map(&:id)
          orders
            .filter { |order| order.in?(editable_orders_ids) }
            .each { |order| OrderDataMasker.new(order).call }
          # Get Line Items
          orders.map(&:line_items).flatten
        end

        private

        def permissions
          @permissions ||= ::Permissions::Order.new(user, ransack_params)
        end
      end
    end
  end
end
