require 'devise/mailers/helpers'
class ProducerMailer < ActionMailer::Base Spree::BaseMailer
  include Devise::Mailers::Helpers

  def order_cycle_report(producer, order_cycle)
    @producer = producer
    @coordinator = order_cycle.coordinator
    @order_cycle = order_cycle
    subject = "[Open Food Network] Order cycle report for "
    mail(to: @producer.email, from: from_address, subject: subject)
  end

end
