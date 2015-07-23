require 'open_food_network/reports/report'

module OpenFoodNetwork::Reports
  class BulkCoopReport < Report


    private

    class << self

      def supplier_name(lis)
        lis.first.variant.product.supplier.name
      end

      def product_name(lis)
        lis.first.variant.product.name
      end

      def group_buy_unit_size(lis)
        (lis.first.variant.product.group_buy_unit_size || 0.0) /
          (lis.first.product.variant_unit_scale || 1)
      end

      def group_buy_unit_size_f(lis)
        if lis.first.variant.product.group_buy
          group_buy_unit_size(lis)
        else
          ""
        end
      end

      def total_amount(lis)
        lis.sum { |li| (li.quantity || 0)     * (li.variant.unit_value || 0) / (li.product.variant_unit_scale || 1) }
      end

      def total_max_quantity_amount(lis)
        lis.sum { |li| (li.max_quantity || 0) * (li.variant.unit_value || 0) / (li.product.variant_unit_scale || 1) }
      end

      def units_required(lis)
        if group_buy_unit_size(lis).zero?
          0
        else
          ( max_quantity_amount(lis) / group_buy_unit_size(lis) ).ceil
        end
      end

      def total_available(lis)
        units_required(lis) * group_buy_unit_size(lis)
      end

      def remainder(lis)
        total_available(lis) - max_quantity_amount(lis)
      end

      def max_quantity_amount(lis)
        lis.sum do |li|
          max_quantity = [li.max_quantity || 0, li.quantity || 0].max
          max_quantity * (li.variant.unit_value || 0) / (li.product.variant_unit_scale || 1)
        end
      end
    end
  end
end
