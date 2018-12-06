Spree::OrderMailer.class_eval do
  helper HtmlHelper
  helper CheckoutHelper
  helper SpreeCurrencyHelper
  include I18nHelper

  def cancel_email(order, resend = false)
    @order = find_order(order)
    I18n.with_locale valid_locale(@order.user.locale) do
      subject = (resend ? "[#{t(:resend).upcase}] " : '')
      subject += "#{Spree::Config[:site_name]} #{t('order_mailer.cancel_email.subject')} ##{order.number}"
      mail(to: order.email, from: from_address, subject: subject)
    end
  end

  def confirm_email_for_customer(order, resend = false)
    find_order(order) # Finds an order instance from an id
    I18n.with_locale valid_locale(@order.user.locale) do
      subject = (resend ? "[#{t(:resend).upcase}] " : '')
      subject += "#{Spree::Config[:site_name]} #{t('order_mailer.confirm_email.subject')} ##{@order.number}"
      mail(:to => @order.email,
           :from => from_address,
           :subject => subject,
           :reply_to => @order.distributor.contact.email)
    end
  end

  def confirm_email_for_shop(order, resend = false)
    find_order(order) # Finds an order instance from an id
    I18n.with_locale valid_locale(@order.user.locale) do
      subject = (resend ? "[#{t(:resend).upcase}] " : '')
      subject += "#{Spree::Config[:site_name]} #{t('order_mailer.confirm_email.subject')} ##{@order.number}"
      mail(:to => @order.distributor.contact.email,
           :from => from_address,
           :subject => subject)
    end
  end

  def invoice_email(order, pdf)
    find_order(order) # Finds an order instance from an id
    I18n.with_locale valid_locale(@order.user.locale) do
      attachments["invoice-#{@order.number}.pdf"] = pdf if pdf.present?
      subject = "#{Spree::Config[:site_name]} #{t(:invoice)} ##{@order.number}"
      mail(:to => @order.email,
           :from => from_address,
           :subject => subject,
          :reply_to => @order.distributor.contact.email)
    end
  end

  def find_order(order)
    @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
  end
end
