# frozen_string_literal: true

RSpec.describe OrderPdfRenderer do
  let(:pdf_renderer) { instance_double(PdfRenderer, render: "%PDF order") }
  let(:service) { described_class.new(ApplicationController.new, pdf_renderer) }
  let(:order) do
    order = create(:completed_order_with_fees)
    order.bill_address = order.ship_address
    order.save!
    order
  end

  it "uses the customer order template" do
    renderer = instance_double(ApplicationController)
    allow(renderer).to receive(:instance_variable_set)
    expect(renderer)
      .to receive(:render_to_string)
      .with(include(template: "spree/orders/print"))
      .and_return("<html>order</html>")

    described_class.new(renderer, pdf_renderer).render_to_string(order)
  end

  it "creates a PDF" do
    expect(service.render_to_string(order)).to match(/^%PDF/)
  end

  it "names the file after the order, not an invoice" do
    expect(service.filename(order)).to eq("order-#{order.number}.pdf")
  end

  describe "the rendered document" do
    subject(:html) do
      renderer = ApplicationController.new
      renderer.instance_variable_set(:@order, order)
      renderer.render_to_string(described_class.new.args)
    end

    it "identifies the order" do
      expect(html).to include(order.number)
    end

    it "is not presented as a tax invoice" do
      expect(html).not_to include(I18n.t(:tax_invoice))
    end

    it "does not create an invoice for the distributor" do
      expect { html }.not_to change { Invoice.count }
    end
  end
end
