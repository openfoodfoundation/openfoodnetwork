require 'open_food_network/distribution_change_validator'

describe DistributionChangeValidator do
  let(:order) { double(:order) }
  let(:subject) { DistributionChangeValidator.new(order) }
  let(:product) { double(:product) }

  describe "checking if an order can change to a specified new distribution" do
    let(:distributor) { double(:distributor) }
    let(:order_cycle) { double(:order_cycle) }

    it "returns false when a variant is not available for the specified distribution" do
      expect(order).to receive(:line_item_variants) { [1] }
      expect(subject).to receive(:variants_available_for_distribution).
        with(distributor, order_cycle) { [] }
      expect(subject.can_change_to_distribution?(distributor, order_cycle)).to be false
    end

    it "returns true when all variants are available for the specified distribution" do
      expect(order).to receive(:line_item_variants) { [1] }
      expect(subject).to receive(:variants_available_for_distribution).
        with(distributor, order_cycle) { [1] }
      expect(subject.can_change_to_distribution?(distributor, order_cycle)).to be true
    end
  end

  describe "finding variants that are available through a particular distribution" do
    it "finds variants distributed by product distribution" do
      v = double(:variant)
      d = double(:distributor, product_distribution_variants: [v])
      oc = double(:order_cycle, variants_distributed_by: [])

      expect(subject.variants_available_for_distribution(d, oc)).to eq([v])
    end

    it "finds variants distributed by product distribution when order cycle is nil" do
      v = double(:variant)
      d = double(:distributor, product_distribution_variants: [v])

      expect(subject.variants_available_for_distribution(d, nil)).to eq([v])
    end

    it "finds variants distributed by order cycle" do
      v = double(:variant)
      d = double(:distributor, product_distribution_variants: [])
      oc = double(:order_cycle)

      expect(oc).to receive(:variants_distributed_by).with(d) { [v] }

      expect(subject.variants_available_for_distribution(d, oc)).to eq([v])
    end

    it "returns an empty array when distributor and order cycle are both nil" do
      expect(subject.variants_available_for_distribution(nil, nil)).to eq([])
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
      allow(order).to receive(:line_item_variants) { line_item_variants }
      enterprise = double(:enterprise)
      allow(enterprise).to receive(:distributed_variants) { line_item_variants } # Exactly the same variants as the order

      expect(subject.available_distributors([enterprise])).to eq([enterprise])
    end

    it "does not match enterprises with no products available" do
      line_item_variants = [variant1, variant3, variant5]
      allow(order).to receive(:line_item_variants) { line_item_variants }
      enterprise = double(:enterprise)
      allow(enterprise).to receive(:distributed_variants) { [] } # No variants

      expect(subject.available_distributors([enterprise])).not_to include enterprise
    end

    it "does not match enterprises with only some of the same variants in the order available" do
      line_item_variants = [variant1, variant3, variant5]
      allow(order).to receive(:line_item_variants) { line_item_variants }
      enterprise_with_some_variants = double(:enterprise)
      allow(enterprise_with_some_variants).to receive(:distributed_variants) { [variant1, variant3] } # Only some variants
      enterprise_with_some_plus_extras = double(:enterprise)
      allow(enterprise_with_some_plus_extras).to receive(:distributed_variants) { [variant1, variant2, variant3, variant4] } # Only some variants, plus extras

      expect(subject.available_distributors([enterprise_with_some_variants])).not_to include enterprise_with_some_variants
      expect(subject.available_distributors([enterprise_with_some_plus_extras])).not_to include enterprise_with_some_plus_extras
    end

    it "matches enterprises which offer all products in the order, plus additional products" do
      line_item_variants = [variant1, variant3, variant5]
      allow(order).to receive(:line_item_variants) { line_item_variants }
      enterprise = double(:enterprise)
      allow(enterprise).to receive(:distributed_variants) { [variant1, variant2, variant3, variant4, variant5] } # Excess variants

      expect(subject.available_distributors([enterprise])).to eq([enterprise])
    end

    it "matches no enterprises when none are provided" do
      expect(subject.available_distributors([])).to eq([])
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
      allow(order).to receive(:line_item_variants) { line_item_variants }
      order_cycle = double(:order_cycle)
      allow(order_cycle).to receive(:distributed_variants) { line_item_variants } # Exactly the same variants as the order

      expect(subject.available_order_cycles([order_cycle])).to eq([order_cycle])
    end

    it "does not match order cycles with no products available" do
      line_item_variants = [variant1, variant3, variant5]
      allow(order).to receive(:line_item_variants) { line_item_variants }
      order_cycle = double(:order_cycle)
      allow(order_cycle).to receive(:distributed_variants) { [] } # No variants

      expect(subject.available_order_cycles([order_cycle])).not_to include order_cycle
    end

    it "does not match order cycles with only some of the same variants in the order available" do
      line_item_variants = [variant1, variant3, variant5]
      allow(order).to receive(:line_item_variants) { line_item_variants }
      order_cycle_with_some_variants = double(:order_cycle)
      allow(order_cycle_with_some_variants).to receive(:distributed_variants) { [variant1, variant3] } # Only some variants
      order_cycle_with_some_plus_extras = double(:order_cycle)
      allow(order_cycle_with_some_plus_extras).to receive(:distributed_variants) { [variant1, variant2, variant3, variant4] } # Only some variants, plus extras

      expect(subject.available_order_cycles([order_cycle_with_some_variants])).not_to include order_cycle_with_some_variants
      expect(subject.available_order_cycles([order_cycle_with_some_plus_extras])).not_to include order_cycle_with_some_plus_extras
    end

    it "matches order cycles which offer all products in the order, plus additional products" do
      line_item_variants = [variant1, variant3, variant5]
      allow(order).to receive(:line_item_variants) { line_item_variants }
      order_cycle = double(:order_cycle)
      allow(order_cycle).to receive(:distributed_variants) { [variant1, variant2, variant3, variant4, variant5] } # Excess variants

      expect(subject.available_order_cycles([order_cycle])).to eq([order_cycle])
    end

    it "matches no order cycles when none are provided" do
      expect(subject.available_order_cycles([])).to eq([])
    end
  end

  describe "checking if a distributor is available for a product" do
    it "returns true when order is nil" do
      subject = DistributionChangeValidator.new(nil)
      expect(subject.distributor_available_for?(product)).to be true
    end

    it "returns true when there's an distributor that can cover the new product" do
      allow(subject).to receive(:available_distributors_for).and_return([1])
      expect(subject.distributor_available_for?(product)).to be true
    end

    it "returns false when there's no distributor that can cover the new product" do
      allow(subject).to receive(:available_distributors_for).and_return([])
      expect(subject.distributor_available_for?(product)).to be false
    end
  end

  describe "checking if an order cycle is available for a product" do
    it "returns true when the order is nil" do
      subject = DistributionChangeValidator.new(nil)
      expect(subject.order_cycle_available_for?(product)).to be true
    end

    it "returns true when the product doesn't require an order cycle" do
      allow(subject).to receive(:product_requires_order_cycle).and_return(false)
      expect(subject.order_cycle_available_for?(product)).to be true
    end

    it "returns true when there's an order cycle that can cover the product" do
      allow(subject).to receive(:product_requires_order_cycle).and_return(true)
      allow(subject).to receive(:available_order_cycles_for).and_return([1])
      expect(subject.order_cycle_available_for?(product)).to be true
    end

    it "returns false otherwise" do
      allow(subject).to receive(:product_requires_order_cycle).and_return(true)
      allow(subject).to receive(:available_order_cycles_for).and_return([])
      expect(subject.order_cycle_available_for?(product)).to be false
    end
  end

  describe "finding available distributors for a product" do
    it "returns enterprises distributing the product when there's no order" do
      subject = DistributionChangeValidator.new(nil)
      allow(Enterprise).to receive(:distributing_products).and_return([1, 2, 3])
      expect(subject).to receive(:available_distributors).never

      expect(subject.available_distributors_for(product)).to eq([1, 2, 3])
    end

    it "returns enterprises distributing the product when there's no order items" do
      allow(order).to receive(:line_items) { [] }
      allow(Enterprise).to receive(:distributing_products).and_return([1, 2, 3])
      expect(subject).to receive(:available_distributors).never

      expect(subject.available_distributors_for(product)).to eq([1, 2, 3])
    end

    it "filters by available distributors when there are order items" do
      allow(order).to receive(:line_items) { [1, 2, 3] }
      allow(Enterprise).to receive(:distributing_products).and_return([1, 2, 3])
      expect(subject).to receive(:available_distributors).and_return([2])

      expect(subject.available_distributors_for(product)).to eq([2])
    end
  end

  describe "finding available order cycles for a product" do
    it "returns order cycles distributing the product when there's no order" do
      subject = DistributionChangeValidator.new(nil)
      allow(OrderCycle).to receive(:distributing_product).and_return([1, 2, 3])
      expect(subject).to receive(:available_order_cycles).never

      expect(subject.available_order_cycles_for(product)).to eq([1, 2, 3])
    end

    it "returns order cycles distributing the product when there's no order items" do
      allow(order).to receive(:line_items) { [] }
      allow(OrderCycle).to receive(:distributing_product).and_return([1, 2, 3])
      expect(subject).to receive(:available_order_cycles).never

      expect(subject.available_order_cycles_for(product)).to eq([1, 2, 3])
    end

    it "filters by available order cycles when there are order items" do
      allow(order).to receive(:line_items) { [1, 2, 3] }
      allow(OrderCycle).to receive(:distributing_product).and_return([1, 2, 3])
      expect(subject).to receive(:available_order_cycles).and_return([2])

      expect(subject.available_order_cycles_for(product)).to eq([2])
    end
  end

  describe "determining if a product requires an order cycle" do
    it "returns true when the product does not have any product distributions" do
      allow(product).to receive(:product_distributions).and_return([])
      expect(subject.product_requires_order_cycle(product)).to be true
    end

    it "returns false otherwise" do
      allow(product).to receive(:product_distributions).and_return([1])
      expect(subject.product_requires_order_cycle(product)).to be false
    end
  end
end
