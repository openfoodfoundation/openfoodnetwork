Spree::OrderMailer.class_eval do
  helper HtmlHelper
  helper CheckoutHelper
  def confirm_email(order, resend = false)
    find_order(order)
    subject = (resend ? "[#{t(:resend).upcase}] " : '')
    subject += "#{Spree::Config[:site_name]} #{t('order_mailer.confirm_email.subject')} ##{@order.number}"
    mail(:to => @order.email, 
         :from => @order.distributor.email || from_address, 
         :subject => subject,
        :cc => "orders@openfoodnetwork.org")
  end
end
