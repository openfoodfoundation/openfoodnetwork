require 'spec_helper'

describe Api::CurrentOrderSerializer do
  let(:distributor) { create(:distributor_enterprise) }
  let(:oc) { create(:simple_order_cycle) }
  let(:li) { create(:line_item, variant: create(:variant)) }
  let(:order) { create(:order, line_items: [li]) }
  let(:serializer) { Api::CurrentOrderSerializer.new(order, current_distributor: distributor, current_order_cycle: oc).to_json }

  it "serializers the current order" do
    expect(serializer).to match order.id.to_s
  end

  it "includes line items" do
    expect(serializer).to match li.id.to_s
  end

  it "includes variants of line items" do
    expect(serializer).to match li.variant.name
  end
end
