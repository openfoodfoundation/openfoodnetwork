# frozen_string_literal: true

require 'spec_helper'

describe Api::CurrentOrderSerializer do
  let(:distributor) { build(:distributor_enterprise) }
  let(:order_cycle) { build(:simple_order_cycle) }
  let(:line_item) { build(:line_item, variant: create(:variant)) }
  let(:order) { build(:order, line_items: [line_item]) }
  let(:serializer) do
    Api::CurrentOrderSerializer.new(
      order,
      current_distributor: distributor,
      current_order_cycle: order_cycle
    ).to_json
  end

  it "serializers the current order" do
    expect(serializer).to match order.id.to_s
  end

  it "includes line items" do
    expect(serializer).to match line_item.id.to_s
  end

  it "includes variants of line items" do
    expect(serializer).to match line_item.variant.name
  end

  context 'when there is no shipment' do
    it 'includes the shipping method of the order' do
      expect(serializer).to match('\"shipping_method_id\":null')
    end
  end

  context 'when there is a shipment' do
    let(:shipping_method) { build(:shipping_method) }

    before do
      allow(order).to receive(:shipping_method).and_return(shipping_method)
    end

    it 'includes the shipping method of the order' do
      expect(serializer).to match("\"shipping_method_id\":#{order.shipping_method.id}")
    end
  end
end
