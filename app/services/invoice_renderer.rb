class InvoiceRenderer
  def render_to_string(order)
    renderer.render_to_string(args(order))
  end

  def args(order)
    {
      pdf: "invoice-#{order.number}.pdf",
      template: invoice_template,
      formats: [:html],
      encoding: "UTF-8",
      locals: { :@order => order }
    }
  end

  private

  def renderer
    ApplicationController.new
  end

  def invoice_template
    if Spree::Config.invoice_style2?
      "spree/admin/orders/invoice2"
    else
      "spree/admin/orders/invoice"
    end
  end
end
