# frozen_string_literal: true

class BulkInvoiceJob < ActiveJob::Base
  def perform(order_ids, filepath)
    pdf = CombinePDF.new

    orders_from(order_ids).each do |order|
      invoice = renderer.render_to_string(order)

      pdf << CombinePDF.parse(invoice)
    end

    pdf.save filepath
  end

  private

  def orders_from(order_ids)
    Spree::Order.where(id: order_ids).order("completed_at DESC")
  end

  def renderer
    @renderer ||= InvoiceRenderer.new
  end
end
