module OpenFoodNetwork
  module Reports
    module Helper
      def admin_and_handling_total(order)
        order.adjustments.select do |a|
          a.eligible && a.originator_type == 'EnterpriseFee' && a.source_type != 'Spree::LineItem'
        end.map(&:amount).sum.to_f
      end

      def ship_total(order)
        order.adjustments.select{ |a| a.originator_type == 'Spree::ShippingMethod' }.
          map(&:amount).sum.to_f
      end

      def payment_fee(order)
        order.adjustments.select{ |a| a.originator_type == 'Spree::PaymentMethod' }.
          map(&:amount).sum.to_f
      end

      def amount_with_adjustments(line_items)
        line_items.map do |line_item|
          price_with_adjustments(line_item) * line_item.quantity
        end.sum
      end

      def price_with_adjustments(line_item)
        return 0 if line_item.quantity.zero?
        (line_item.price + line_item_adjustments(line_item).map(&:amount).sum / line_item.quantity).
          round(2)
      end

      def line_item_adjustments(line_item)
        line_item.order.adjustments.select{ |a| a.source_id == line_item.id }
      end

      def shipping_method(line_items)
        line_items.first.order.shipments.first.
          andand.shipping_rates.andand.first.andand.shipping_method
      end
    end
  end
end
