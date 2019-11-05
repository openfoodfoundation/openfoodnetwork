class ProducerMailer < Spree::BaseMailer
  include I18nHelper

  def order_cycle_report(producer, order_cycle)
    @producer = producer
    @coordinator = order_cycle.coordinator
    @order_cycle = order_cycle
    line_items = line_items_from(@order_cycle, @producer)
    @grouped_line_items = line_items.group_by(&:product_and_full_name)
    @receival_instructions = @order_cycle.receival_instructions_for @producer
    @total = total_from_line_items(line_items)
    @tax_total = tax_total_from_line_items(line_items)

    I18n.with_locale valid_locale(@producer.owner) do
      order_cycle_subject = I18n.t('producer_mailer.order_cycle.subject', producer: producer.name)
      subject = "[#{Spree::Config.site_name}] #{order_cycle_subject}"

      return unless has_orders?(order_cycle, producer)

      mail(
        to: @producer.contact.email,
        from: from_address,
        subject: subject,
        reply_to: @coordinator.contact.email,
        cc: @coordinator.contact.email
      )
    end
  end

  private

  def has_orders?(order_cycle, producer)
    line_items_from(order_cycle, producer).any?
  end

  def line_items_from(order_cycle, producer)
    Spree::LineItem.
      includes(variant: { option_values: :option_type }).
      from_order_cycle(order_cycle).
      sorted_by_name_and_unit_value.
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
