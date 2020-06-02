# frozen_string_literal: true

require 'spec_helper'

describe OrderCartReset do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order) { create(:order, :with_line_item, distributor: distributor) }

  context "if order distributor is not the requested distributor" do
    let(:new_distributor) { create(:distributor_enterprise) }

    it "empties order" do
      OrderCartReset.new(order, new_distributor.id.to_s).reset_distributor

      expect(order.line_items).to be_empty
    end
  end

  context "if the order's order cycle is not in the list of visible order cycles" do
    let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
    let(:order_cycle_list) { instance_double(Shop::OrderCyclesList) }

    before do
      expect(Shop::OrderCyclesList).to receive(:new).and_return(order_cycle_list)
      order.update_attribute :order_cycle, order_cycle
    end

    it "empties order and makes order cycle nil" do
      expect(order_cycle_list).to receive(:call).and_return([])

      OrderCartReset.new(order, distributor.id.to_s).reset_other!(nil, nil)

      expect(order.line_items).to be_empty
      expect(order.order_cycle).to be_nil
    end

    it "selects default Order Cycle if there's one" do
      other_order_cycle = create(:simple_order_cycle, distributors: [distributor])
      expect(order_cycle_list).to receive(:call).and_return([other_order_cycle])

      OrderCartReset.new(order, distributor.id.to_s).reset_other!(nil, nil)

      expect(order.order_cycle).to eq other_order_cycle
    end
  end
end
