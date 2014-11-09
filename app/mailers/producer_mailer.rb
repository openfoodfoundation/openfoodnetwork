
class ProducerMailer < Spree::BaseMailer

  def order_cycle_report(producer, order_cycle)
    @producer = producer
    @coordinator = order_cycle.coordinator
    @order_cycle = order_cycle

    # TODO: consider what happens if there is more than one distributor
    first_producer = @order_cycle.distributors[0]
    @distribution_date = @order_cycle.pickup_time_for first_producer
    # puts @distribution_date

    subject = "[Open Food Network] Order cycle report for #{@distribution_date}"
    mail(to: @producer.email, from: from_address, subject: subject)
  end

end
