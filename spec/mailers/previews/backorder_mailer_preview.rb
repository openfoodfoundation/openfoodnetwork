# frozen_string_literal: true

class BackorderMailerPreview < ActionMailer::Preview
  def backorder_failed
    order = Spree::Order.complete.last || Spree::Order.last

    BackorderMailer.backorder_failed(
      order,
      order.line_items.map(&:variant),
    )
  end

  def backorder_incomplete
    order = Spree::Order.complete.last || Spree::Order.last
    order_cycle = order.order_cycle
    distributor = order.distributor
    user = distributor.owner
    order_id = "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/Orders/1177603473714"

    BackorderMailer.backorder_incomplete(
      user, distributor, order_cycle, order_id
    )
  end
end
