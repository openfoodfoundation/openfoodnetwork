require 'open_food_network/order_cycle_distributed_variants'

describe OrderCycleDistributedVariants do
  let(:order) { double(:order) }
  let(:subject) { OrderCycleDistributedVariants.new(order) }
  let(:product) { double(:product) }

  describe "checking if an order can change to a specified new distribution" do
    let(:distributor) { double(:distributor) }
    let(:order_cycle) { double(:order_cycle) }

    it "returns false when a variant is not available for the specified distribution" do
      order.should_receive(:line_item_variants) { [1] }
      subject.should_receive(:variants_available_for_distribution).
        with(distributor, order_cycle) { [] }
      expect(subject.can_change_to_distribution?(distributor, order_cycle)).to be false
    end

    it "returns true when all variants are available for the specified distribution" do
      order.should_receive(:line_item_variants) { [1] }
      subject.should_receive(:variants_available_for_distribution).
        with(distributor, order_cycle) { [1] }
      expect(subject.can_change_to_distribution?(distributor, order_cycle)).to be true
    end
  end

  describe "finding variants that are available through a particular order cycle" do
    it "finds variants distributed by order cycle" do
      variant = double(:variant)
      distributor = double(:distributor)
      order_cycle = double(:order_cycle)

      order_cycle.should_receive(:variants_distributed_by).with(distributor) { [variant] }

      expect(subject.variants_available_for_distribution(distributor, order_cycle)).to eq [variant]
    end

    it "returns an empty array when order cycle is nil" do
      expect(subject.variants_available_for_distribution(nil, nil)).to eq []
    end
  end
end
