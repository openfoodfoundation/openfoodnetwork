# frozen_string_literal: true

class Admin::OrdersReflex < ApplicationReflex
  def capture
    order = Spree::Order.find_by(id: element.dataset[:id])
    authorize! :admin, order

    payment_capture = OrderCaptureService.new(order)

    if payment_capture.call
      morph dom_id(order), render(partial: "spree/admin/orders/table_row",
                                  locals: { order: order.reload, success: true })
    else
      flash[:error] = with_locale{ payment_capture.gateway_error || I18n.t(:payment_processing_failed) }
      morph_admin_flashes
    end
  end
end
