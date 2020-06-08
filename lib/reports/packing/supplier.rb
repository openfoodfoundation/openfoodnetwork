# frozen_string_literal: true

module Reports
  module Packing
    class Supplier < Base
      def report_row(object)
        {
          hub: orders[object.order_id].distributor.name,
          supplier: object.product.supplier.name,
          customer_code: orders[object.order_id].customer&.code,
          first_name: orders[object.order_id].bill_address.firstname,
          last_name: orders[object.order_id].bill_address.lastname,
          product: object.product.name,
          variant: object.full_name,
          quantity: object.quantity,
          is_temperature_controlled: temp_controlled_value(object)
        }
      end

      def ordering
        [:hub, :supplier, :product, :variant, :last_name]
      end

      def summary_group
        :supplier
      end
    end
  end
end
