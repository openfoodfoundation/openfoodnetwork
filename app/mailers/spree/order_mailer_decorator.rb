Spree::OrderMailer.class_eval do
  helper HtmlHelper
  helper CheckoutHelper
  helper SpreeCurrencyHelper

  def confirm_email_for_customer(order_or_order_id, resend = false)
    @order = find_order(order_or_order_id)
    subject = build_subject(t('order_mailer.confirm_email.subject'), resend)
    mail(:to => @order.email,
         :from => from_address,
         :subject => subject,
         :reply_to => @order.distributor.contact.email)
  end

  def confirm_email_for_shop(order_or_order_id, resend = false)
    @order = find_order(order_or_order_id)
    subject = build_subject(t('order_mailer.confirm_email.subject'), resend)
    mail(:to => @order.distributor.contact.email,
         :from => from_address,
         :subject => subject)
  end

  def invoice_email(order_or_order_id, pdf)
    @order = find_order(order_or_order_id)
    subject = build_subject(t(:invoice))
    attachments["invoice-#{@order.number}.pdf"] = pdf if pdf.present?
    mail(:to => @order.email,
         :from => from_address,
         :subject => subject,
         :reply_to => @order.distributor.contact.email)
  end

  private

  # Finds an order instance from an order or from an order id
  def find_order(order_or_order_id)
    order_or_order_id.respond_to?(:id) ? order_or_order_id : Spree::Order.find(order_or_order_id)
  end

  def build_subject( subject_text, resend = false )
    subject = (resend ? "[#{t(:resend).upcase}] " : "")
    subject += "#{Spree::Config[:site_name]} #{subject_text} ##{@order.number}"
  end
end
