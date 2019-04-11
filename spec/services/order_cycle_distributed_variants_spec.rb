require 'spec_helper'

describe OrderCycleDistributedVariants do
  let(:order) { double(:order) }
  let(:distributor) { double(:distributor) }
  let(:order_cycle) { double(:order_cycle) }  
  let(:subject) { OrderCycleDistributedVariants.new(order_cycle, distributor) }
  let(:product) { double(:product) }

  describe "checking if an order can change to a specified new distribution" do
    it "returns false when a variant is not available for the specified distribution" do
      order.should_receive(:line_item_variants) { [1] }
      subject.should_receive(:available_variants) { [] }
      expect(subject.distributes_order_variants?(order)).to be false
    end

    it "returns true when all variants are available for the specified distribution" do
      order.should_receive(:line_item_variants) { [1] }
      subject.should_receive(:available_variants) { [1] }
      expect(subject.distributes_order_variants?(order)).to be true
    end
  end

  describe "finding variants that are available through a particular order cycle" do
    it "finds variants distributed by order cycle" do
      variant = double(:variant)
      order_cycle.should_receive(:variants_distributed_by).with(distributor) { [variant] }

      expect(subject.available_variants).to eq [variant]
    end

    it "returns an empty array when order cycle is nil" do
      subject = OrderCycleDistributedVariants.new(nil, nil)
      expect(subject.available_variants).to eq []
    end
  end
end
