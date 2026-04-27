# frozen_string_literal: true

class InvoiceRenderer
  def initialize(renderer = ApplicationController.new, user = nil, pdf_renderer = PdfRenderer.new)
    @renderer = renderer
    @user = user
    @pdf_renderer = pdf_renderer
  end

  def render_to_string(order, user = @user)
    renderer.instance_variable_set(:@order, order)
    html = renderer.render_to_string(args(user))

    pdf_renderer.render(html, display_url:)
  end

  def args(user = @user)
    @user = user
    {
      template: invoice_template,
      formats: [:html],
      encoding: "UTF-8",
      layout: false
    }
  end

  def filename(order)
    "invoice-#{order.number}.pdf"
  end

  private

  attr_reader :renderer, :pdf_renderer

  def display_url
    return unless renderer.respond_to?(:request)

    request = renderer.request
    request.original_url if request.respond_to?(:original_url)
  rescue StandardError
    nil
  end

  def invoice_template
    if OpenFoodNetwork::FeatureToggle.enabled?(:invoices, @user)
      invoice_template_v3
    elsif Spree::Config.invoice_style2?
      "spree/admin/orders/invoice2"
    else
      "spree/admin/orders/invoice"
    end
  end

  def invoice_template_v3
    "spree/admin/orders/invoice4"
  end
end
