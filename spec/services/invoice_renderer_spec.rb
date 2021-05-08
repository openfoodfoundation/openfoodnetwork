# frozen_string_literal: true

require 'spec_helper'
require 'spree/payment_methods_helper'

describe InvoiceRenderer do
  include Spree::PaymentMethodsHelper

  let(:service) { described_class.new }
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
        .to receive(:render_to_string_with_wicked_pdf)
        .with(include(template: 'spree/admin/orders/invoice2'))

      described_class.new(renderer).render_to_string(order)
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
        .to receive(:render_to_string_with_wicked_pdf)
        .with(include(template: 'spree/admin/orders/invoice'))

      described_class.new(renderer).render_to_string(order)
    end

    it 'creates a PDF invoice' do
      result = service.render_to_string(order)
      expect(result).to match /^%PDF/
    end
  end
end
