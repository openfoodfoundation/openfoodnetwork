# frozen_string_literal: true

class PaypalItemsBuilder
  def initialize(order)
    @order = order
  end

  def call
    items = order.line_items.map(&method(:line_item))

    tax_adjustments = order.adjustments.tax.additional
    shipping_adjustments = order.adjustments.shipping

    order.adjustments.eligible.each do |adjustment|
      next if (tax_adjustments + shipping_adjustments).include?(adjustment)

      items << {
        Name: adjustment.label,
        Quantity: 1,
        Amount: {
          currencyID: order.currency,
          value: adjustment.amount
        }
      }
    end

    # Because PayPal doesn't accept $0 items at all.
    # See https://github.com/spree-contrib/better_spree_paypal_express/issues/10
    # "It can be a positive or negative value but not zero."
    items.reject! do |item|
      item[:Amount][:value].zero?
    end

    items
  end

  private

  attr_reader :order

  def line_item(item)
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
end
