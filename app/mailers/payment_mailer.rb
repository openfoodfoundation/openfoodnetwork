# frozen_string_literal: true

class PaymentMailer < ApplicationMailer
  include I18nHelper
  helper MailerHelper

  def authorize_payment(payment)
    @payment = payment
    @order = @payment.order
    @hide_ofn_navigation = @payment.order.distributor.hide_ofn_navigation
    I18n.with_locale valid_locale(@payment.order.user) do
      subject = t('.subject',
                  number: @order.number,
                  distributor: @order.distributor.name)
      mail(to: payment.order.email, subject:)
    end
  end

  def authorization_required(payment)
    @payment = payment
    @order = @payment.order
    shop_owner = @payment.order.distributor.owner
    I18n.with_locale valid_locale(shop_owner) do
      subject = t('.subject',
                  number: @order.number,
                  distributor: @order.distributor.name)
      mail(to: shop_owner.email,
           subject:)
    end
  end
end
