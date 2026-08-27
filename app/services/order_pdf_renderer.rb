# frozen_string_literal: true

# Renders the customer's own copy of their order as a PDF.
#
# This is deliberately not an invoice. It reuses the content of the order confirmation email,
# carries no invoice number or issue date, and writes nothing to the distributor's invoice
# ledger. See InvoiceRenderer for the admin invoice path.
class OrderPdfRenderer
  TEMPLATE = "spree/orders/print"

  def initialize(renderer = ApplicationController.new, pdf_renderer = PdfRenderer.new)
    @renderer = renderer
    @pdf_renderer = pdf_renderer
  end

  def render_to_string(order)
    renderer.instance_variable_set(:@order, order)

    pdf_renderer.render(renderer.render_to_string(args))
  end

  def filename(order)
    "order-#{order.number}.pdf"
  end

  def args
    {
      template: TEMPLATE,
      formats: [:html],
      encoding: "UTF-8",
      layout: false
    }
  end

  private

  attr_reader :renderer, :pdf_renderer
end
