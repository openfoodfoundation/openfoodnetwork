# frozen_string_literal: true

require 'spec_helper'

describe Api::CurrentOrderSerializer do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle) }
  let(:line_item) { create(:line_item, variant: create(:variant)) }
  let(:order) { create(:order, line_items: [line_item]) }
  let(:serializer) { Api::CurrentOrderSerializer.new(order, current_distributor: distributor, current_order_cycle: order_cycle).to_json }

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
    before { create(:shipment, order: order) }

    it 'includes the shipping method of the order' do
      expect(serializer).to match("\"shipping_method_id\":#{order.shipping_method.id}")
    end
  end
end
