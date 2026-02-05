# frozen_string_literal: true

class PaymentMailer < ApplicationMailer
  include I18nHelper

  def authorize_payment(payment)
    @payment = payment
    @order = @payment.order
    I18n.with_locale valid_locale(@order.user) do
      mail(to: @order.email,
           subject: default_i18n_subject(distributor: @order.distributor.name),
           reply_to: @order.distributor.contact.email)
    end
  end

  def authorization_required(payment)
    @order = payment.order
    shop_owner = @order.distributor.owner
    I18n.with_locale valid_locale(shop_owner) do
      mail(to: shop_owner.email, reply_to: @order.email)
    end
  end

  def refund_available(payment, taler_order_status_url)
    @order = payment.order
    @shop = @order.distributor.name
    @taler_order_status_url = taler_order_status_url

    I18n.with_locale valid_locale(@order.user) do
      mail(to: @order.email,
           subject: default_i18n_subject(shop: @shop),
           reply_to: @order.email)
    end
  end
end
