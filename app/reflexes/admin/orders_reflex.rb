# frozen_string_literal: true

module Admin
  class OrdersReflex < ApplicationReflex
    before_reflex :authorize_order, only: [:capture, :ship]

    def capture
      payment_capture = Orders::CaptureService.new(@order)

      if payment_capture.call
        cable_ready.replace(selector: dom_id(@order),
                            html: render(partial: "spree/admin/orders/table_row",
                                         locals: { order: @order.reload, success: true }))
        morph :nothing
      else
        flash[:error] = payment_capture.gateway_error || I18n.t(:payment_processing_failed)
        morph_admin_flashes
      end
    end

    def ship
      @order.send_shipment_email = false unless params[:send_shipment_email]
      if @order.ship
        paths = %w[edit customer payments adjustments invoices return_authorizations].freeze
        return set_param_for_controller if Regexp.union(paths).match? request.url

        morph dom_id(@order), render(partial: "spree/admin/orders/table_row",
                                     locals: { order: @order.reload, success: true })
      else
        flash[:error] = I18n.t("api.orders.failed_to_update")
        morph_admin_flashes
      end
    end

    def cancel_orders(params)
      cancelled_orders = Orders::BulkCancelService.new(params, current_user).call

      cable_ready.dispatch_event(name: "modal:close")

      cancelled_orders.each do |order|
        cable_ready.replace(
          selector: dom_id(order),
          html: render(partial: "spree/admin/orders/table_row", locals: { order: })
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
      editable_orders.invoiceable.where(id: params[:bulk_ids]).find_each do |o|
        next unless o.distributor.can_invoice?

        Spree::OrderMailer.invoice_email(o.id, current_user_id: current_user.id).deliver_later
        count += 1
      end

      success("admin.send_invoice_feedback", count)
    end

    private

    def authorize_order
      id = element.dataset[:id] || params[:id]
      @order = Spree::Order.find_by(id:)
      authorize! :admin, @order
    end

    def success(i18n_key, count)
      flash[:success] = I18n.t(i18n_key, count:)
      cable_ready.dispatch_event(name: "modal:close")
      morph_admin_flashes
    end

    def editable_orders
      Permissions::Order.new(current_user).editable_orders
    end

    def set_param_for_controller
      params[:id] = @order.number
    end
  end
end
