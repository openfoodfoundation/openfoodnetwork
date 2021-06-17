# frozen_string_literal: true

module OpenFoodNetwork
  class OrdersAndFulfillmentsReport
    class DistributorTotalsBySupplierReport
      REPORT_TYPE = "order_cycle_distributor_totals_by_supplier"

      attr_reader :context

      def initialize(context)
        @context = context
      end

      def header
        [I18n.t(:report_header_hub), I18n.t(:report_header_producer),
         I18n.t(:report_header_product), I18n.t(:report_header_variant),
         I18n.t(:report_header_quantity), I18n.t(:report_header_curr_cost_per_unit),
         I18n.t(:report_header_total_cost), I18n.t(:report_header_total_shipping_cost),
         I18n.t(:report_header_shipping_method)]
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def rules
        [
          {
            group_by: proc { |line_item| line_item.order.distributor },
            sort_by: proc { |distributor| distributor.name },
            summary_columns: [
              proc { |_line_items| "" },
              proc { |_line_items| I18n.t('admin.reports.total') },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |line_items| line_items.sum(&:amount) },
              proc { |line_items| line_items.map(&:order).uniq.sum(&:ship_total) },
              proc { |_line_items| "" }
            ]
          },
          {
            group_by: proc { |line_item| line_item.variant.product.supplier },
            sort_by: proc { |supplier| supplier.name }
          },
          {
            group_by: proc { |line_item| line_item.variant.product },
            sort_by: proc { |product| product.name }
          },
          {
            group_by: proc { |line_item| line_item.variant.full_name },
            sort_by: proc { |full_name| full_name }
          }
        ]
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Metrics/AbcSize
      def columns
        [proc { |line_items| line_items.first.order.distributor.name },
         proc { |line_items| line_items.first.variant.product.supplier.name },
         proc { |line_items| line_items.first.variant.product.name },
         proc { |line_items| line_items.first.variant.full_name },
         proc { |line_items| line_items.to_a.sum(&:quantity) },
         proc { |line_items| line_items.first.price },
         proc { |line_items| line_items.sum(&:amount) },
         proc { |_line_items| "" },
         proc { |_line_items| I18n.t(:report_header_shipping_method) }]
      end
      # rubocop:enable Metrics/AbcSize

      def line_item_includes
        [{ order: [:distributor, :adjustments, { shipments: { shipping_rates: :shipping_method } }],
           variant: [{ option_values: :option_type }, { product: :supplier }] }]
      end
    end
  end
end
