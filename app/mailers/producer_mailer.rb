class ProducerMailer < Spree::BaseMailer

  def order_cycle_report(producer, order_cycle)
    @producer = producer
    @coordinator = order_cycle.coordinator
    @order_cycle = order_cycle
    @line_items = aggregated_line_items_from(@order_cycle, @producer)
    @receival_instructions = @order_cycle.receival_instructions_for @producer

    subject = "[#{Spree::Config.site_name}] Order cycle report for #{producer.name}"

    if has_orders? order_cycle, producer
      mail(to: @producer.email,
           from: from_address,
           subject: subject,
           reply_to: @coordinator.email,
           cc: @coordinator.email)
    end
  end

  private

  def has_orders?(order_cycle, producer)
    line_items_from(order_cycle, producer).any?
  end

  def aggregated_line_items_from(order_cycle, producer)
    aggregate_line_items line_items_from(order_cycle, producer)
  end

  def line_items_from(order_cycle, producer)
    Spree::LineItem.
      joins(order: :order_cycle, variant: :product).
      where('order_cycles.id = ?', order_cycle).
      merge(Spree::Product.in_supplier(producer)).
      merge(Spree::Order.complete)
  end

  def aggregate_line_items(line_items)
    # Arrange the items in a hash to group quantities
    line_items.inject({}) do |lis, li|
      if lis.key? li.variant
        lis[li.variant].quantity += li.quantity
      else
        lis[li.variant] = li
      end

      lis
    end
  end
end
