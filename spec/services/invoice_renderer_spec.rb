require 'spec_helper'

describe InvoiceRenderer do
  let(:service) { described_class.new }

  it "creates a PDF invoice" do
    order = create(:completed_order_with_fees)
    order.bill_address = order.ship_address
    order.save!

    result = service.render_to_string(order)

    expect(result).to match /^%PDF/
  end
end
