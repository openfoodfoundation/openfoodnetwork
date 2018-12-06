Spree::OrderMailer.class_eval do
  helper HtmlHelper
  helper CheckoutHelper
  helper SpreeCurrencyHelper
  include I18nHelper

  def cancel_email(order, resend = false)
    @order = find_order(order)
    I18n.with_locale valid_locale(@order.user) do
      mail(to: order.email,
           from: from_address,
           subject: mail_subject(t('order_mailer.cancel_email.subject'), resend))
    end
  end

  def confirm_email_for_customer(order, resend = false)
    find_order(order) # Finds an order instance from an id
    I18n.with_locale valid_locale(@order.user) do
      mail(to: @order.email,
           from: from_address,
           subject: mail_subject(t('order_mailer.confirm_email.subject'), resend),
           reply_to: @order.distributor.contact.email)
    end
  end

  def confirm_email_for_shop(order, resend = false)
    find_order(order) # Finds an order instance from an id
    I18n.with_locale valid_locale(@order.user) do
      mail(to: @order.distributor.contact.email,
           from: from_address,
           subject: mail_subject(t('order_mailer.confirm_email.subject'), resend))
    end
  end

  def invoice_email(order, pdf)
    find_order(order) # Finds an order instance from an id
    attach_file("invoice-#{@order.number}.pdf", pdf)
    I18n.with_locale valid_locale(@order.user) do
      mail(to: @order.email,
           from: from_address,
           subject: mail_subject(t(:invoice), false),
           reply_to: @order.distributor.contact.email)
    end
  end

  def find_order(order)
    @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
  end

  private

  def mail_subject(base_subject, resend)
    resend_prefix = (resend ? "[#{t(:resend).upcase}] " : '')
    "#{resend_prefix}#{Spree::Config[:site_name]} #{base_subject} ##{@order.number}"
  end

  def attach_file(filename, file)
    attachments[filename] = file if file.present?
  end
end
