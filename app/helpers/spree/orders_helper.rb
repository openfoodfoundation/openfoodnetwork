module Spree
  module OrdersHelper
    def order_delivery_fee_subtotal(order, options={})
      options.reverse_merge! :format_as_currency => true
      amount = order.line_items.map { |li| li.itemwise_shipping_cost }.sum
      options.delete(:format_as_currency) ? number_to_currency(amount) : amount
    end

    def alternative_available_distributors(order)
      DistributorChangeValidator.new(order).available_distributors(Enterprise.all) - [order.distributor]
    end
  end
end
