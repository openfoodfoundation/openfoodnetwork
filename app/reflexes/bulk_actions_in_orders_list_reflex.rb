# frozen_string_literal: true

class BulkActionsInOrdersListReflex < ApplicationReflex
  def resend_confirmation_email(order_ids)
    orders(order_ids).find_each do |o|
      Spree::OrderMailer.confirm_email_for_customer(o.id, true).deliver_later if can? :resend, o
    end

    success("admin.resend_confirmation_emails_feedback", order_ids.count)
  end

  def send_invoice(order_ids)
    count = 0
    orders(order_ids).find_each do |o|
      next unless o.distributor.can_invoice? && (o.resumed? || o.complete?)

      Spree::OrderMailer.invoice_email(o.id).deliver_later
      count += 1
    end

    success("admin.send_invoice_feedback", count)
  end

  private

  def success(i18n_key, count)
    flash[:success] = I18n.t(i18n_key, count: count)
    cable_ready.dispatch_event(name: "modal:close")
    morph "#flashes", render(partial: "shared/flashes", locals: { flashes: flash })
  end

  def orders(order_ids)
    Spree::Order.where(id: order_ids)
  end
end
