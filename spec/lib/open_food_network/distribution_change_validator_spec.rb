require 'open_food_network/distribution_change_validator'

describe DistributionChangeValidator do
  let(:order) { double(:order) }
  let(:subject) { DistributionChangeValidator.new(order) }
  let(:product) { double(:product) }

  describe "checking if an order can change to a specified new distribution" do
    let(:distributor) { double(:distributor) }
    let(:order_cycle) { double(:order_cycle) }

    it "returns false when a variant is not available for the specified distribution" do
      order.should_receive(:line_item_variants) { [1] }
      subject.should_receive(:variants_available_for_distribution).
        with(distributor, order_cycle) { [] }
      subject.can_change_to_distribution?(distributor, order_cycle).should be false
    end

    it "returns true when all variants are available for the specified distribution" do
      order.should_receive(:line_item_variants) { [1] }
      subject.should_receive(:variants_available_for_distribution).
        with(distributor, order_cycle) { [1] }
      subject.can_change_to_distribution?(distributor, order_cycle).should be true
    end
  end

  describe "finding variants that are available through a particular distribution" do
    it "finds variants distributed by product distribution" do
      v = double(:variant)
      d = double(:distributor, product_distribution_variants: [v])
      oc = double(:order_cycle, variants_distributed_by: [])

      subject.variants_available_for_distribution(d, oc).should == [v]
    end

    it "finds variants distributed by product distribution when order cycle is nil" do
      v = double(:variant)
      d = double(:distributor, product_distribution_variants: [v])

      subject.variants_available_for_distribution(d, nil).should == [v]
    end

    it "finds variants distributed by order cycle" do
      v = double(:variant)
      d = double(:distributor, product_distribution_variants: [])
      oc = double(:order_cycle)

      oc.should_receive(:variants_distributed_by).with(d) { [v] }

      subject.variants_available_for_distribution(d, oc).should == [v]
    end

    it "returns an empty array when distributor and order cycle are both nil" do
      subject.variants_available_for_distribution(nil, nil).should == []
    end
  end
end
