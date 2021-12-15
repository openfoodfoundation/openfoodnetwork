# frozen_string_literal: true

class BulkInvoiceJob < ActiveJob::Base
  def perform(order_ids, filepath)
    pdf = CombinePDF.new

    sorted_orders(order_ids).each do |order|
      invoice = renderer.render_to_string(order)

      pdf << CombinePDF.parse(invoice)
    end

    pdf.save filepath
  end

  private

  # Ensures the records are returned in the same order the ids were originally given in
  def sorted_orders(order_ids)
    Spree::Order.where(id: order_ids).to_a.sort_by{ |order| order_ids.index(order.id) }
  end

  def renderer
    @renderer ||= InvoiceRenderer.new
  end
end
