# frozen_string_literal: true

class OrderInvoiceGenerator
  def initialize(order)
    @order = order
  end

  def generate_or_update_latest_invoice
    if comparator.can_generate_new_invoice?
      order.invoices.create!(
        date: Time.zone.today,
        number: total_invoices_created_by_distributor + 1,
        data: invoice_data
      )
    elsif comparator.can_update_latest_invoice?
      order.invoices.latest.update!(
        date: Time.zone.today,
        data: invoice_data
      )
    end
  end

  private

  attr_reader :order

  def comparator
    @comparator ||= OrderInvoiceComparator.new(order)
  end

  def invoice_data
    @invoice_data ||= InvoiceDataGenerator.new(order).generate
  end

  def total_invoices_created_by_distributor
    Invoice.joins(:order).where(order: { distributor: order.distributor }).count
  end
end
