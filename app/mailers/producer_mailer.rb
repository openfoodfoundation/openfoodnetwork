require 'devise/mailers/helpers'

class ProducerMailer < Spree::BaseMailer
  include Devise::Mailers::Helpers

  def order_cycle_report(producer, order_cycle)
    @producer = producer
    @coordinator = order_cycle.coordinator
    @order_cycle = order_cycle

    subject = "[#{Spree::Config[:site_name]}] Order cycle report"

    if @order_cycle.distributors.count > 0
      first_producer = @order_cycle.distributors[0]
      @distribution_date = @order_cycle.pickup_time_for first_producer
      subject += " for #{@distribution_date}" if @distribution_date.size > 0
    end

    @orders = Spree::Order.complete.not_state(:canceled).managed_by(@producer.owner)
    @line_items = []
    @orders.each do |o|
      @line_items += o.line_items.managed_by(@producer.owner)
    end

    mail(to: @producer.email,
         from: from_address,
         subject: subject,
         reply_to: @coordinator.email,
         cc: @coordinator.email)
  end

end
