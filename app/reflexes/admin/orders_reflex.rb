# frozen_string_literal: true

class Admin::OrdersReflex < ApplicationReflex
  before_reflex :authorize_order, only: [:capture, :ship]

  def capture
    payment_capture = OrderCaptureService.new(@order)

    if payment_capture.call
      morph dom_id(@order), render(partial: "spree/admin/orders/table_row",
                                   locals: { order: @order.reload, success: true })
    else
      flash[:error] = with_locale{ payment_capture.gateway_error || I18n.t(:payment_processing_failed) }
      morph_admin_flashes
    end
  end

  def ship
    if @order.ship
      morph dom_id(@order), render(partial: "spree/admin/orders/table_row",
                                   locals: { order: @order.reload, success: true })
    else
      flash[:error] = with_locale{ I18n.t("api.orders.failed_to_update") }
      morph_admin_flashes
    end
  end

  def bulk_invoice(params)
    cable_ready.append(
      selector: "#orders-index",
      html: render(partial: "spree/admin/orders/bulk/invoice_modal")
    ).broadcast

    BulkInvoiceJob.perform_later(
      params[:bulk_ids],
      "tmp/invoices/#{Time.zone.now.to_i}-#{SecureRandom.hex(2)}.pdf",
      channel: SessionChannel.for_request(request)
    )

    morph :nothing
  end

  private

  def authorize_order
    @order = Spree::Order.find_by(id: element.dataset[:id])
    authorize! :admin, @order
  end
end
