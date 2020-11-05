# frozen_string_literal: true

require 'spec_helper'

describe InvoiceRenderer do
  let(:service) { described_class.new }

  it "creates a PDF invoice with two different templates" do
    order = create(:completed_order_with_fees)
    order.bill_address = order.ship_address
    order.save!

    result = service.render_to_string(order)
    expect(result).to match /^%PDF/

    allow(Spree::Config).to receive(:invoice_style2?).and_return true

    alternative = service.render_to_string(order)
    expect(alternative).to match /^%PDF/
    expect(alternative).to_not eq result
  end
end
