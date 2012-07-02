module Spree
  module OrdersHelper
    def order_delivery_fee_subtotal(order)
      number_to_currency order.line_items.map { |li| li.itemwise_shipping_cost }.sum
    end
  end
end
