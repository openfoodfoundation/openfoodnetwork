# frozen_string_literal: true

class PaymentMailer < ApplicationMailer
  include I18nHelper

  def authorize_payment(payment)
    @payment = payment
    subject = I18n.t('spree.payment_mailer.authorize_payment.subject',
                     distributor: @payment.order.distributor.name)
    I18n.with_locale valid_locale(@payment.order.user) do
      mail(to: payment.order.email, subject: subject)
    end
  end

  def authorization_required(payment)
    @payment = payment
    shop_owner = @payment.order.distributor.owner
    subject = I18n.t('spree.payment_mailer.authorization_required.subject',
                     order: @payment.order)
    I18n.with_locale valid_locale(shop_owner) do
      mail(to: shop_owner.email,
           subject: subject)
    end
  end
end
