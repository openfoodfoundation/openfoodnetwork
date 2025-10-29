# frozen_string_literal: true

class PaymentMailer < ApplicationMailer
  include I18nHelper

  def authorize_payment(payment)
    @payment = payment
    @order = @payment.order
    @hide_ofn_navigation = @payment.order.distributor.hide_ofn_navigation
    subject = I18n.t('spree.payment_mailer.authorize_payment.subject',
                     distributor: @order.distributor.name)
    I18n.with_locale valid_locale(@order.user) do
      mail(to: @order.email,
           subject:,
           reply_to: @order.distributor.contact.email)
    end
  end

  def authorization_required(payment)
    @order = payment.order
    shop_owner = @order.distributor.owner
    subject = I18n.t('spree.payment_mailer.authorization_required.subject',
                     order: @order)
    I18n.with_locale valid_locale(shop_owner) do
      mail(to: shop_owner.email,
           subject:,
           reply_to: @order.email)
    end
  end
end
