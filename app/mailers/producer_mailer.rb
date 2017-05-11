class ProducerMailer < Spree::BaseMailer

  def order_cycle_report(producer, order_cycle)
    @producer = producer
    @coordinator = order_cycle.coordinator
    @order_cycle = order_cycle
    line_items = line_items_from(@order_cycle, @producer)
    @grouped_line_items = line_items.group_by(&:product_and_full_name)
    @receival_instructions = @order_cycle.receival_instructions_for @producer
    @total = total_from_line_items(line_items)
    @tax_total = tax_total_from_line_items(line_items)

    subject = "[#{Spree::Config.site_name}] #{I18n.t('producer_mailer.order_cycle.subject', producer: producer.name)}"

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

  def line_items_from(order_cycle, producer)
    Spree::LineItem.
      joins(:order => :order_cycle, :variant => :product).
      where('order_cycles.id = ?', order_cycle).
      merge(Spree::Product.in_supplier(producer)).
      merge(Spree::Order.by_state('complete'))
  end

  def total_from_line_items(line_items)
    Spree::Money.new line_items.sum(&:total)
  end

  def tax_total_from_line_items(line_items)
    Spree::Money.new line_items.sum(&:included_tax)
  end
end
