# frozen_string_literal: true

module OpenFoodNetwork
  class OrdersAndFulfillmentsReport
    class DefaultReport
      delegate :line_item_name, :supplier_name, :product_name, :line_items_name, to: :context

      def initialize(context)
        @context = context
      end

      def header
        [
          I18n.t(:report_header_producer),
          I18n.t(:report_header_product),
          I18n.t(:report_header_variant),
          I18n.t(:report_header_quantity),
          I18n.t(:report_header_curr_cost_per_unit),
          I18n.t(:report_header_total_cost),
          I18n.t(:report_header_status),
          I18n.t(:report_header_incoming_transport)
        ]
      end

      def rules
        [
          {
            group_by: proc { |line_item| line_item.variant.product.supplier },
            sort_by: proc { |supplier| supplier.name }
          },
          {
            group_by: proc { |line_item| line_item.variant.product },
            sort_by: proc { |product| product.name }
          },
          {
            group_by: line_item_name,
            sort_by: proc { |full_name| full_name }
          }
        ]
      end

      def columns
        [
          supplier_name,
          product_name,
          line_items_name,
          proc { |line_items| line_items.to_a.sum(&:quantity) },
          proc { |line_items| line_items.first.price },
          proc { |line_items| line_items.sum { |li| li.quantity * li.price } },
          proc { |_line_items| "" },
          proc { |_line_items| I18n.t(:report_header_incoming_transport) }
        ]
      end

      def line_item_includes
        []
      end

      private

      attr_reader :context
    end
  end
end
