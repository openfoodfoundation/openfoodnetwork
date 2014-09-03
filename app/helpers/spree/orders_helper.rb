module Spree
  module OrdersHelper
    def cart_is_empty
      order = current_order(false)
      order.nil? || order.line_items.empty?
    end

    def order_distribution_subtotal(order, options={})
      options.reverse_merge! :format_as_currency => true
      amount = order.adjustments.enterprise_fee.sum &:amount
      options.delete(:format_as_currency) ? Spree::Money.new(amount).to_s : amount
    end

    def alternative_available_distributors(order)
      DistributionChangeValidator.new(order).available_distributors(Enterprise.all) - [order.distributor]
    end

    def last_completed_order
      spree_current_user.orders.complete.last
    end

    def cart_count
      current_order.andand.line_items.andand.count || 0
    end
  end
end
