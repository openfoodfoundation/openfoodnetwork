# frozen_string_literal: true

class PaypalItemsBuilder
  def initialize(order)
    @order = order
  end

  def call
    items = order.line_items.map(&method(:line_item_data))

    relevant_adjustments.each do |adjustment|
      items << adjustment_data(adjustment)
    end

    # Because PayPal doesn't accept $0 items at all.
    # See https://github.com/spree-contrib/better_spree_paypal_express/issues/10
    # "It can be a positive or negative value but not zero."
    items.reject do |item|
      item[:Amount][:value].zero?
    end
  end

  private

  attr_reader :order

  def relevant_adjustments
    # Tax total and shipping costs are added separately, so they're not included here.
    order.all_adjustments.eligible - order.all_adjustments.tax - order.all_adjustments.shipping
  end

  def line_item_data(item)
    {
      Name: item.product.name,
      Number: item.variant.sku,
      Quantity: item.quantity,
      Amount: {
        currencyID: item.order.currency,
        value: item.price
      },
      ItemCategory: "Physical"
    }
  end

  def adjustment_data(adjustment)
    {
      Name: adjustment.label,
      Quantity: 1,
      Amount: {
        currencyID: order.currency,
        value: adjustment.amount
      }
    }
  end
end
