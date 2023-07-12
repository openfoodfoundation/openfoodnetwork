# frozen_string_literal: true

module Admin
  class OrdersReflex < ApplicationReflex
    before_reflex :authorize_order, only: [:capture, :ship]

    def capture
      payment_capture = OrderCaptureService.new(@order)

      if payment_capture.call
        morph dom_id(@order), render(partial: "spree/admin/orders/table_row",
                                     locals: { order: @order.reload, success: true })
      else
        flash[:error] = with_locale{
          payment_capture.gateway_error || I18n.t(:payment_processing_failed)
        }
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

    def cancel_orders(params)
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

    def resend_confirmation_emails(params)
      editable_orders.where(id: params[:bulk_ids]).find_each do |order|
        next unless can? :resend, order

        Spree::OrderMailer.confirm_email_for_customer(order.id, true).deliver_later
      end

      success("admin.resend_confirmation_emails_feedback", params[:bulk_ids].count)
    end

    def send_invoices(params)
      count = 0
      editable_orders.where(id: params[:bulk_ids]).find_each do |o|
        next unless o.distributor.can_invoice? && o.invoiceable?

        Spree::OrderMailer.invoice_email(o.id).deliver_later
        count += 1
      end

      success("admin.send_invoice_feedback", count)
    end

    private

    def authorize_order
      @order = Spree::Order.find_by(id: element.dataset[:id])
      authorize! :admin, @order
    end

    def success(i18n_key, count)
      flash[:success] = with_locale { I18n.t(i18n_key, count: count) }
      cable_ready.dispatch_event(name: "modal:close")
      morph_admin_flashes
    end

    def editable_orders
      Permissions::Order.new(current_user).editable_orders
    end
  end
end
