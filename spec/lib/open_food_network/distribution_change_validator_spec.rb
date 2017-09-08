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

  describe "finding distributors which have the same variants" do
    let(:variant1) { double(:variant) }
    let(:variant2) { double(:variant) }
    let(:variant3) { double(:variant) }
    let(:variant4) { double(:variant) }
    let(:variant5) { double(:variant) }

    it "matches enterprises which offer all products within the order" do
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants) { line_item_variants }
      enterprise = double(:enterprise)
      enterprise.stub(:distributed_variants) { line_item_variants } # Exactly the same variants as the order

      subject.available_distributors([enterprise]).should == [enterprise]
    end

    it "does not match enterprises with no products available" do
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants) { line_item_variants }
      enterprise = double(:enterprise)
      enterprise.stub(:distributed_variants) { [] } # No variants

      subject.available_distributors([enterprise]).should_not include enterprise
    end

    it "does not match enterprises with only some of the same variants in the order available" do
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants) { line_item_variants }
      enterprise_with_some_variants = double(:enterprise)
      enterprise_with_some_variants.stub(:distributed_variants) { [variant1, variant3] } # Only some variants
      enterprise_with_some_plus_extras = double(:enterprise)
      enterprise_with_some_plus_extras.stub(:distributed_variants) { [variant1, variant2, variant3, variant4] } # Only some variants, plus extras

      subject.available_distributors([enterprise_with_some_variants]).should_not include enterprise_with_some_variants
      subject.available_distributors([enterprise_with_some_plus_extras]).should_not include enterprise_with_some_plus_extras
    end

    it "matches enterprises which offer all products in the order, plus additional products" do
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants) { line_item_variants }
      enterprise = double(:enterprise)
      enterprise.stub(:distributed_variants) { [variant1, variant2, variant3, variant4, variant5] } # Excess variants

      subject.available_distributors([enterprise]).should == [enterprise]
    end

    it "matches no enterprises when none are provided" do
      subject.available_distributors([]).should == []
    end
  end

  describe "finding order cycles which have the same variants" do
    let(:variant1) { double(:variant) }
    let(:variant2) { double(:variant) }
    let(:variant3) { double(:variant) }
    let(:variant4) { double(:variant) }
    let(:variant5) { double(:variant) }

    it "matches order cycles which offer all products within the order" do
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants) { line_item_variants }
      order_cycle = double(:order_cycle)
      order_cycle.stub(:distributed_variants) { line_item_variants } # Exactly the same variants as the order

      subject.available_order_cycles([order_cycle]).should == [order_cycle]
    end

    it "does not match order cycles with no products available" do
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants) { line_item_variants }
      order_cycle = double(:order_cycle)
      order_cycle.stub(:distributed_variants) { [] } # No variants

      subject.available_order_cycles([order_cycle]).should_not include order_cycle
    end

    it "does not match order cycles with only some of the same variants in the order available" do
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants) { line_item_variants }
      order_cycle_with_some_variants = double(:order_cycle)
      order_cycle_with_some_variants.stub(:distributed_variants) { [variant1, variant3] } # Only some variants
      order_cycle_with_some_plus_extras = double(:order_cycle)
      order_cycle_with_some_plus_extras.stub(:distributed_variants) { [variant1, variant2, variant3, variant4] } # Only some variants, plus extras

      subject.available_order_cycles([order_cycle_with_some_variants]).should_not include order_cycle_with_some_variants
      subject.available_order_cycles([order_cycle_with_some_plus_extras]).should_not include order_cycle_with_some_plus_extras
    end

    it "matches order cycles which offer all products in the order, plus additional products" do
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants) { line_item_variants }
      order_cycle = double(:order_cycle)
      order_cycle.stub(:distributed_variants) { [variant1, variant2, variant3, variant4, variant5] } # Excess variants

      subject.available_order_cycles([order_cycle]).should == [order_cycle]
    end

    it "matches no order cycles when none are provided" do
      subject.available_order_cycles([]).should == []
    end
  end

  describe "checking if a distributor is available for a product" do
    it "returns true when order is nil" do
      subject = DistributionChangeValidator.new(nil)
      subject.distributor_available_for?(product).should be true
    end

    it "returns true when there's an distributor that can cover the new product" do
      subject.stub(:available_distributors_for).and_return([1])
      subject.distributor_available_for?(product).should be true
    end

    it "returns false when there's no distributor that can cover the new product" do
      subject.stub(:available_distributors_for).and_return([])
      subject.distributor_available_for?(product).should be false
    end
  end

  describe "checking if an order cycle is available for a product" do
    it "returns true when the order is nil" do
      subject = DistributionChangeValidator.new(nil)
      subject.order_cycle_available_for?(product).should be true
    end

    it "returns true when the product doesn't require an order cycle" do
      subject.stub(:product_requires_order_cycle).and_return(false)
      subject.order_cycle_available_for?(product).should be true
    end

    it "returns true when there's an order cycle that can cover the product" do
      subject.stub(:product_requires_order_cycle).and_return(true)
      subject.stub(:available_order_cycles_for).and_return([1])
      subject.order_cycle_available_for?(product).should be true
    end

    it "returns false otherwise" do
      subject.stub(:product_requires_order_cycle).and_return(true)
      subject.stub(:available_order_cycles_for).and_return([])
      subject.order_cycle_available_for?(product).should be false
    end
  end

  describe "finding available distributors for a product" do
    it "returns enterprises distributing the product when there's no order" do
      subject = DistributionChangeValidator.new(nil)
      Enterprise.stub(:distributing_products).and_return([1, 2, 3])
      subject.should_receive(:available_distributors).never

      subject.available_distributors_for(product).should == [1, 2, 3]
    end

    it "returns enterprises distributing the product when there's no order items" do
      order.stub(:line_items) { [] }
      Enterprise.stub(:distributing_products).and_return([1, 2, 3])
      subject.should_receive(:available_distributors).never

      subject.available_distributors_for(product).should == [1, 2, 3]
    end

    it "filters by available distributors when there are order items" do
      order.stub(:line_items) { [1, 2, 3] }
      Enterprise.stub(:distributing_products).and_return([1, 2, 3])
      subject.should_receive(:available_distributors).and_return([2])

      subject.available_distributors_for(product).should == [2]
    end
  end

  describe "finding available order cycles for a product" do
    it "returns order cycles distributing the product when there's no order" do
      subject = DistributionChangeValidator.new(nil)
      OrderCycle.stub(:distributing_product).and_return([1, 2, 3])
      subject.should_receive(:available_order_cycles).never

      subject.available_order_cycles_for(product).should == [1, 2, 3]
    end

    it "returns order cycles distributing the product when there's no order items" do
      order.stub(:line_items) { [] }
      OrderCycle.stub(:distributing_product).and_return([1, 2, 3])
      subject.should_receive(:available_order_cycles).never

      subject.available_order_cycles_for(product).should == [1, 2, 3]
    end

    it "filters by available order cycles when there are order items" do
      order.stub(:line_items) { [1, 2, 3] }
      OrderCycle.stub(:distributing_product).and_return([1, 2, 3])
      subject.should_receive(:available_order_cycles).and_return([2])

      subject.available_order_cycles_for(product).should == [2]
    end
  end

  describe "determining if a product requires an order cycle" do
    it "returns true when the product does not have any product distributions" do
      product.stub(:product_distributions).and_return([])
      subject.product_requires_order_cycle(product).should be true
    end

    it "returns false otherwise" do
      product.stub(:product_distributions).and_return([1])
      subject.product_requires_order_cycle(product).should be false
    end
  end
end
