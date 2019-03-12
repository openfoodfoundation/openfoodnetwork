require "spec_helper"

describe AdvanceOrderService do
  let!(:order) do
    create(:order_with_totals_and_distribution, bill_address: create(:address),
                                                ship_address: create(:address))
  end

  let(:service) { described_class.new(order) }

  it "transitions the order multiple steps" do
    expect(order.state).to eq("cart")
    service.call
    order.reload
    expect(order.state).to eq("complete")
  end
end
