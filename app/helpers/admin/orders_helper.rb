module Admin
  module OrdersHelper
    def order_adjustments(order)
      order.adjustments.eligible.select do |adjustment|
        type = adjustment.originator_type

        is_shipping_method_fee = (type == 'Spree::ShippingMethod')
        is_zero_tax_rate = (type == 'Spree::TaxRate' && adjustment.amount.zero?)

        !is_shipping_method_fee && !is_zero_tax_rate
      end
    end
  end
end
