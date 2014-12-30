
class ProducerMailer < Spree::BaseMailer

  def order_cycle_report(producer, order_cycle)
    @producer = producer
    @coordinator = order_cycle.coordinator
    @order_cycle = order_cycle

    subject = "[#{Spree::Config[:site_name]}] Order cycle report"

    # if @order_cycle.distributors.any?
    #   first_producer = @order_cycle.distributors.first
    #   @distribution_date = @order_cycle.pickup_time_for first_producer
    #   subject += " for #{@distribution_date}" if @distribution_date.present?
    # end

    # TODO: what if producer handling orders into multiple order cycles?
    @orders = Spree::Order.complete.not_state(:canceled).managed_by(@producer.owner)
    # puts @orders.size

    # Create a single flat list of all line items
    @line_items = @orders.map(&:line_items).flatten
    # Arrange the items in a hash to group quantities
    @line_items.inject({}) do |lis, li|
      lis[li.variant] ||= {line_item: li, quantity: 0}
      lis[li.variant][:quantity] += li.quantity
      lis
    end

    mail(to: @producer.email,
         from: from_address,
         subject: subject,
         reply_to: @coordinator.email,
         cc: @coordinator.email)
  end

end
