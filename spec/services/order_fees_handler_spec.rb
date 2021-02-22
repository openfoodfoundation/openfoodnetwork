# frozen_string_literal: true

require 'spec_helper'

describe OrderFeesHandler do
  let(:order_cycle) { create(:order_cycle) }
  let(:order) { create(:order_with_line_items, line_items_count: 1, order_cycle: order_cycle) }
  let(:line_item) { order.line_items.first }

  let(:service) { OrderFeesHandler.new(order) }
  let(:calculator) {
    double(OpenFoodNetwork::EnterpriseFeeCalculator, create_order_adjustments_for: true)
  }

  before do
    allow(service).to receive(:calculator) { calculator }
  end

  describe "#create_line_item_fees!" do
    it "creates per-line-item fee adjustments for line items in the order cycle" do
      allow(service).to receive(:provided_by_order_cycle?) { true }
      expect(calculator).to receive(:create_line_item_adjustments_for).with(line_item)

      service.create_line_item_fees!
    end
  end

  describe "#create_order_fees!" do
    it "creates per-order adjustment for the order cycle" do
      expect(calculator).to receive(:create_order_adjustments_for).with(order)
      service.create_order_fees!
    end

    it "skips per-order fee adjustments for orders that don't have an order cycle" do
      allow(service).to receive(:order_cycle) { nil }
      expect(calculator).to_not receive(:create_order_adjustments_for)

      service.create_order_fees!
    end
  end

  context "checking if a line item can be provided by the order cycle" do
    it "returns true when the variant is provided" do
      allow(order_cycle).to receive(:variants) { [line_item.variant] }

      expect(service.__send__(:provided_by_order_cycle?, line_item)).to be true
    end

    it "returns false otherwise" do
      allow(order_cycle).to receive(:variants) { [] }

      expect(service.__send__(:provided_by_order_cycle?, line_item)).to be false
    end

    it "returns false when there is no order cycle" do
      allow(order).to receive(:order_cycle) { nil }

      expect(service.__send__(:provided_by_order_cycle?, line_item)).to be false
    end
  end
end
