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
        group_buy_unit_size(lis)
      end

      def total_amount(lis)
        lis.sum { |li| scaled_final_weight_volume(li) }
      end

      def units_required(lis)
        if group_buy_unit_size(lis).zero?
          0
        else
          ( total_amount(lis) / group_buy_unit_size(lis) ).ceil
        end
      end

      def total_available(lis)
        units_required(lis) * group_buy_unit_size(lis)
      end

      def remainder(lis)
        remainder = total_available(lis) - total_amount(lis)
        remainder >= 0 ? remainder : ''
      end

      def max_quantity_excess(lis)
        max_quantity_amount(lis) - total_amount(lis)
      end

      def max_quantity_amount(lis)
        lis.sum do |li|
          max_quantity = [li.max_quantity || 0, li.quantity || 0].max
          max_quantity * scaled_unit_value(li.variant)
        end
      end

      def scaled_final_weight_volume(li)
        (li.final_weight_volume || 0) / (li.product.variant_unit_scale || 1)
      end

      def scaled_unit_value(v)
        (v.unit_value || 0) / (v.product.variant_unit_scale || 1)
      end
    end
  end
end
