# frozen_string_literal: true

class PaymentMailer < Spree::BaseMailer
  include I18nHelper

  def authorize_payment(payment)
    @payment = payment
    subject = I18n.t('spree.payment_mailer.authorize_payment.subject',
                     distributor: @payment.order.distributor.name)
    mail(to: payment.order.user.email,
         from: from_address,
         subject: subject)
  end
end
