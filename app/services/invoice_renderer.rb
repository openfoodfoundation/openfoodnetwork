# frozen_string_literal: true

class InvoiceRenderer
  def initialize(renderer = ApplicationController.new, user = nil)
    @renderer = renderer
    @user = user
  end

  def render_to_string(order, user = @user)
    renderer.instance_variable_set(:@order, order)
    renderer.render_to_string_with_wicked_pdf(args(order, user))
  end

  def args(order, user = @user)
    @user = user
    {
      pdf: "invoice-#{order.number}.pdf",
      template: invoice_template,
      formats: [:html],
      encoding: "UTF-8"
    }
  end

  private

  attr_reader :renderer

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
