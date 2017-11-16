class StandingOrderMailer < Spree::BaseMailer
  helper CheckoutHelper

  def confirmation_email(order)
    @type = 'confirmation'
    @order = order
    send_mail(order)
  end

  def empty_email(order, changes)
    @type = 'empty'
    @changes = changes
    @order = order
    send_mail(order)
  end

  def placement_email(order, changes)
    @type = 'placement'
    @changes = changes
    @order = order
    send_mail(order)
  end

  private

  def send_mail(order)
    subject = "#{Spree::Config[:site_name]} #{t('order_mailer.confirm_email.subject')} ##{order.number}"
    mail(:to => order.email,
         :from => from_address,
         :subject => subject,
         :reply_to => order.distributor.email)
  end
end
