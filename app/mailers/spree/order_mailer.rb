# frozen_string_literal: true

module Spree
  class OrderMailer < BaseMailer
    helper 'checkout'
    helper SpreeCurrencyHelper
    helper Spree::PaymentMethodsHelper
    helper OrderHelper
    helper MailerHelper
    include I18nHelper

    def cancel_email(order_or_order_id, resend = false)
      @order = find_order(order_or_order_id)
      I18n.with_locale valid_locale(@order.user) do
        mail(to: @order.email,
             from: from_address,
             subject: mail_subject(t('spree.order_mailer.cancel_email.subject'), resend))
      end
    end

    def cancel_email_for_shop(order)
      @order = order
      I18n.with_locale valid_locale(@order.distributor.owner) do
        subject = I18n.t('spree.order_mailer.cancel_email_for_shop.subject')
        mail(to: @order.distributor.contact.email,
             from: from_address,
             subject: subject)
      end
    end

    def confirm_email_for_customer(order_or_order_id, resend = false)
      @order = find_order(order_or_order_id)
      I18n.with_locale valid_locale(@order.user) do
        subject = mail_subject(t('spree.order_mailer.confirm_email.subject'), resend)
        mail(to: @order.email,
             from: from_address,
             subject: subject,
             reply_to: @order.distributor.contact.email)
      end
    end

    def confirm_email_for_shop(order_or_order_id, resend = false)
      @order = find_order(order_or_order_id)
      I18n.with_locale valid_locale(@order.user) do
        subject = mail_subject(t('spree.order_mailer.confirm_email.subject'), resend)
        mail(to: @order.distributor.contact.email,
             from: from_address,
             subject: subject)
      end
    end

    def invoice_email(order_or_order_id, pdf)
      @order = find_order(order_or_order_id)
      attach_file("invoice-#{@order.number}.pdf", pdf)
      I18n.with_locale valid_locale(@order.user) do
        mail(to: @order.email,
             from: from_address,
             subject: mail_subject(t(:invoice), false),
             reply_to: @order.distributor.contact.email)
      end
    end

    private

    # Finds an order instance from an order or from an order id
    def find_order(order_or_order_id)
      order_or_order_id.respond_to?(:id) ? order_or_order_id : Spree::Order.find(order_or_order_id)
    end

    def mail_subject(base_subject, resend)
      resend_prefix = (resend ? "[#{t(:resend).upcase}] " : '')
      "#{resend_prefix}#{Spree::Config[:site_name]} #{base_subject} ##{@order.number}"
    end

    def attach_file(filename, file)
      attachments[filename] = file if file.present?
    end
  end
end
