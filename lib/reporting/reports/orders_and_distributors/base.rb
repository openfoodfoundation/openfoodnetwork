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
            product: proc { |line_item| line_item.product.name },
            variant: proc { |line_item| line_item.full_name },
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
          report_line_items.orders
        end

        def query_result
          report_line_items.list(line_item_includes)
        end

        private

        def line_item_includes
          [{ variant: [:supplier, :product],
             order: [:bill_address, :payments, { distributor: :address }] }]
        end

        def permissions
          @permissions ||= ::Permissions::Order.new(user, ransack_params)
        end

        def report_line_items
          @report_line_items ||= Reporting::LineItems.new(permissions, params)
        end
      end
    end
  end
end
