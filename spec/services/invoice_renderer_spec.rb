# frozen_string_literal: true

RSpec.describe InvoiceRenderer do
  include Spree::PaymentMethodsHelper

  let(:pdf_renderer) { instance_double(PdfRenderer, render: "%PDF invoice") }
  let(:service) { described_class.new(ApplicationController.new, nil, pdf_renderer) }
  let(:order) do
    order = create(:completed_order_with_fees)
    order.bill_address = order.ship_address
    order.save!
    order
  end

  context 'when invoice_style2 is configured' do
    before { allow(Spree::Config).to receive(:invoice_style2?).and_return(true) }

    it 'uses the invoice2 template' do
      renderer = instance_double(ApplicationController)
      expect(renderer)
        .to receive(:render_to_string)
        .with(include(template: 'spree/admin/orders/invoice2'))
        .and_return("<html>invoice</html>")

      described_class.new(renderer, nil, pdf_renderer).render_to_string(order)
    end

    it 'creates a PDF invoice' do
      result = service.render_to_string(order)
      expect(result).to match /^%PDF/
    end
  end

  context 'when invoice_style2 is not configured' do
    before { allow(Spree::Config).to receive(:invoice_style2?).and_return(false) }

    it 'uses the invoice template' do
      renderer = instance_double(ApplicationController)
      expect(renderer)
        .to receive(:render_to_string)
        .with(include(template: 'spree/admin/orders/invoice'))
        .and_return("<html>invoice</html>")

      described_class.new(renderer, nil, pdf_renderer).render_to_string(order)
    end

    it 'creates a PDF invoice' do
      result = service.render_to_string(order)
      expect(result).to match /^%PDF/
    end
  end

  describe '#display_url (via render_to_string)' do
    it 'returns nil when renderer.request raises a StandardError' do
      renderer = instance_double(ApplicationController)
      allow(renderer).to receive(:respond_to?).with(:request).and_return(true)
      allow(renderer).to receive(:request).and_raise(StandardError, "broken request")
      allow(renderer).to receive(:render_to_string).and_return("<html></html>")
      allow(renderer).to receive(:instance_variable_set)

      expect(pdf_renderer).to receive(:render).with("<html></html>", display_url: nil)
      described_class.new(renderer, nil, pdf_renderer).render_to_string(order)
    end
  end
end
