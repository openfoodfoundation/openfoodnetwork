# frozen_string_literal: true

class BackorderMailerPreview < ActionMailer::Preview
  def backorder_failed
    order = Spree::Order.complete.last || Spree::Order.last

    BackorderMailer.backorder_failed(
      order,
      order.line_items.map(&:variant),
    )
  end
end
