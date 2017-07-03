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

  context 'when there is no shipment' do
    it 'includes the shipping method of the order' do
      expect(serializer).to match('\"shipping_method_id\":null')
    end
  end

  context 'when there is a shipment' do
    before { create(:shipment, order: order, shipping_method: shipping_method) }

    let(:shipping_method) { create(:shipping_method) }

    it 'includes the shipping method of the order' do
      expect(serializer).to match("\"shipping_method_id\":#{shipping_method.id}")
    end
  end
end
