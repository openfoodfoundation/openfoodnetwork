# frozen_string_literal: true

class BulkActionsInOrdersListReflex < ApplicationReflex
  def resend_confirmation_email(order_ids)
    Spree::Order.where(id: order_ids).find_each do |o|
      Spree::OrderMailer.confirm_email_for_customer(o.id, true).deliver_later if can? :resend, o
    end

    flash[:success] = I18n.t("admin.resend_confirmation_emails_feedback", count: order_ids.count)
    cable_ready.dispatch_event(name: "modal:close")
    morph "#flashes", render(partial: "shared/flashes", locals: { flashes: flash })
  end

  def send_invoice(order_ids)
    Spree::Order.where(id: order_ids).find_each do |o|
      Spree::OrderMailer.invoice_email(o.id).deliver_later unless o.distributor.can_invoice?
    end

    flash[:success] = I18n.t("admin.send_invoice_feedback", count: order_ids.count)
    cable_ready.dispatch_event(name: "modal:close")
    morph "#flashes", render(partial: "shared/flashes", locals: { flashes: flash })
  end
end
