# frozen_string_literal: true

class CancelOrdersReflex < ApplicationReflex
  def confirm(params)
    cancelled_orders = OrdersBulkCancelService.new(params, current_user).call

    cable_ready.dispatch_event(name: "modal:close")

    cancelled_orders.each do |order|
      cable_ready.replace(
        selector: dom_id(order),
        html: render(partial: "spree/admin/orders/table_row", locals: { order: order })
      )
    end

    cable_ready.broadcast
    morph :nothing
  end
end
