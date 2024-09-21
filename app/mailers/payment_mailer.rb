# frozen_string_literal: true

class PaymentMailer < ApplicationMailer
  include I18nHelper
  helper MailerHelper

  def authorize_payment(payment)
    @payment = payment
    @order = @payment.order
    @hide_ofn_navigation = @payment.order.distributor.hide_ofn_navigation
    subject = I18n.t('spree.payment_mailer.authorize_payment.subject',
                     distributor: @payment.order.distributor.name)
    I18n.with_locale valid_locale(@payment.order.user) do
      mail(to: payment.order.email, subject:)
    end
  end

  def authorization_required(payment)
    @payment = payment
    @order = @payment.order
    shop_owner = @payment.order.distributor.owner
    subject = I18n.t('spree.payment_mailer.authorization_required.subject',
                     order: @payment.order)
    I18n.with_locale valid_locale(shop_owner) do
      mail(to: shop_owner.email,
           subject:)
    end
  end
end
