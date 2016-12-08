Spree::OrderMailer.class_eval do
  helper HtmlHelper
  helper CheckoutHelper
  helper SpreeCurrencyHelper

  def cancel_email(order, resend = false)
    @order = find_order(order)
    subject = (resend ? "[#{t(:resend).upcase}] " : '')
    subject += "#{Spree::Config[:site_name]} #{t('order_mailer.cancel_email.subject')} ##{order.number}"
    mail(to: order.email, from: from_address, subject: subject)
  end

  def confirm_email_for_customer(order, resend = false)
    find_order(order) # Finds an order instance from an id
    subject = (resend ? "[#{t(:resend).upcase}] " : '')
    subject += "#{Spree::Config[:site_name]} #{t('order_mailer.confirm_email.subject')} ##{@order.number}"
    mail(:to => @order.email,
         :from => from_address,
         :subject => subject,
         :reply_to => @order.distributor.email)
  end

  def confirm_email_for_shop(order, resend = false)
    find_order(order) # Finds an order instance from an id
    subject = (resend ? "[#{t(:resend).upcase}] " : '')
    subject += "#{Spree::Config[:site_name]} #{t('order_mailer.confirm_email.subject')} ##{@order.number}"
    mail(:to => @order.distributor.email,
         :from => from_address,
         :subject => subject)
  end

  def invoice_email(order, pdf)
    find_order(order) # Finds an order instance from an id
    attachments["invoice-#{@order.number}.pdf"] = pdf if pdf.present?
    subject = "#{Spree::Config[:site_name]} #{t(:invoice)} ##{@order.number}"
    mail(:to => @order.email,
         :from => from_address,
         :subject => subject,
         :reply_to => @order.distributor.email)
  end

  def standing_order_email(order, type, changes)
    @type = type
    @changes = changes
    find_order(order) # Finds an order instance from an id
    subject = "#{Spree::Config[:site_name]} #{t('order_mailer.confirm_email.subject')} ##{@order.number}"
    mail(:to => @order.email,
         :from => from_address,
         :subject => subject,
         :reply_to => @order.distributor.email)
  end

  def find_order(order)
    @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
  end
end
