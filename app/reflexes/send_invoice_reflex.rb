# frozen_string_literal: true

class SendInvoiceReflex < ApplicationReflex
  def confirm(order_ids)
    Spree::Order.where(id: order_ids).find_each do |o|
      Spree::OrderMailer.invoice_email(o.id).deliver_later unless o.distributor.can_invoice?
    end

    flash[:success] = I18n.t("admin.send_invoice_feedback", count: order_ids.count)
    cable_ready.dispatch_event(name: "modal:close")
    morph "#flashes", render(partial: "shared/flashes", locals: { flashes: flash })
  end
end
