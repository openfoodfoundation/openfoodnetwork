# frozen_string_literal: true

class ResendConfirmationEmailReflex < ApplicationReflex
  def confirm(order_ids)
    Spree::Order.where(id: order_ids).find_each do |o|
      Spree::OrderMailer.confirm_email_for_customer(o.id, true).deliver_later
    end

    flash[:success] = I18n.t("admin.resend_confirmation_emails_feedback", count: order_ids.count)
    cable_ready.dispatch_event(name: "modal:close")
    morph "#flashes", render(partial: "shared/flashes", locals: { flashes: flash })
  end
end
