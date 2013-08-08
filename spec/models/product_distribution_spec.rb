require 'spec_helper'

describe ProductDistribution do
  it "is unique for scope [product, distributor]" do
    pd1 = create(:product_distribution)
    pd1.should be_valid

    new_product = create(:product)
    new_distributor = create(:distributor_enterprise)

    pd2 = build(:product_distribution, :product => pd1.product, :distributor => pd1.distributor)
    pd2.should_not be_valid

    pd2 = build(:product_distribution, :product => pd1.product, :distributor => new_distributor)
    pd2.should be_valid

    pd2 = build(:product_distribution, :product => new_product, :distributor => pd1.distributor)
    pd2.should be_valid

    pd2 = build(:product_distribution, :product => new_product, :distributor => new_distributor)
    pd2.should be_valid
  end


  describe "adjusting orders" do
    context "integration" do
      it "creates an adjustment for product distributions" do
        # Given an order
        distributor = create(:distributor_enterprise)
        order = create(:order, distributor: distributor)

        # And a product with a product distribution with an enterprise fee
        product = create(:product)
        enterprise_fee = create(:enterprise_fee, calculator: build(:calculator))
        enterprise_fee.calculator.preferred_amount = 1.23
        enterprise_fee.calculator.save!
        create(:product_distribution, product: product, distributor: distributor, enterprise_fee: enterprise_fee)

        # When I add the product to the order, an adjustment should be made
        expect do
          op = Spree::OrderPopulator.new order, 'AU'
          op.populate products: {product.id => product.master.id}, quantity: 1, distributor_id: distributor.id
        end.to change(Spree::Adjustment, :count).by(1)

        # And it should have the correct data
        order.reload
        order.line_items.count.should == 1
        order.line_items.last.adjustments.count.should == 1
        adjustment = order.line_items.last.adjustments.last

        adjustment.source.should == enterprise_fee
        adjustment.originator.should == enterprise_fee
        adjustment.label.should == "Product distribution by #{distributor.name}"
        adjustment.amount.should == 1.23

        # And it should have some associated metadata
        pending 'Needs metadata spec'
      end
    end

    describe "ensuring that a line item has the correct adjustment" do
      let(:enterprise_fee) { EnterpriseFee.new }
      let(:pd) { ProductDistribution.new enterprise_fee: enterprise_fee }
      let(:line_item) { double(:line_item) }
      let(:adjustment) { double(:adjustment) }

      # TODO: This spec will go away once enterprise_fee is required
      it "does nothing if there is no enterprise fee set" do
        pd.enterprise_fee = nil
        pd.should_receive(:adjustment_on).never
        pd.ensure_correct_adjustment_for line_item
      end

      describe "adding items to cart" do
        it "creates an adjustment for the new item" do
          pd.stub(:adjustment_on) { nil }
          pd.should_receive(:create_adjustment_on).with(line_item)

          pd.ensure_correct_adjustment_for line_item
        end

        it "makes no change to the adjustment of existing items" do
          pd.stub(:adjustment_on) { adjustment }
          pd.should_receive(:create_adjustment_on).never

          pd.ensure_correct_adjustment_for line_item
        end
      end

      describe "changing distributor" do
        it "clears and re-creates the adjustment on the line item"
      end
    end

    describe "finding our adjustment on a line item" do
      it "returns nil when not present" do
        line_item = build(:line_item)
        pd = ProductDistribution.new
        pd.send(:adjustment_on, line_item).should be_nil
      end

      it "returns the adjustment when present" do
        # TODO: This spec can be simplified (ie. use the default ProductDistribution factory)
        # once Spree's calculators are compatible with LineItem targets, not just Orders.
        distributor = create(:distributor_enterprise)
        enterprise_fee = create(:enterprise_fee, enterprise: distributor, calculator: build(:calculator))

        pd = create(:product_distribution, distributor: distributor, enterprise_fee: enterprise_fee)
        line_item = create(:line_item)
        adjustment = pd.enterprise_fee.create_adjustment('foo', line_item, pd.enterprise_fee, true)

        pd.send(:adjustment_on, line_item).should == adjustment
      end

      it "raises an error when there are multiple adjustments for this enterprise fee" do
        # TODO: This spec can be simplified (ie. use the default ProductDistribution factory)
        # once Spree's calculators are compatible with LineItem targets, not just Orders.
        distributor = create(:distributor_enterprise)
        enterprise_fee = create(:enterprise_fee, enterprise: distributor, calculator: build(:calculator))

        pd = create(:product_distribution, distributor: distributor, enterprise_fee: enterprise_fee)
        line_item = create(:line_item)
        pd.enterprise_fee.create_adjustment('one', line_item, pd.enterprise_fee, true)
        pd.enterprise_fee.create_adjustment('two', line_item, pd.enterprise_fee, true)

        expect do
          pd.send(:adjustment_on, line_item)
        end.to raise_error "Multiple adjustments for this enterprise fee on this line item. This method is not designed to deal with this scenario."
      end
    end

    describe "creating an adjustment on a line item" do
      it "creates the adjustment via the enterprise fee" do
        # TODO: This spec can be simplified (ie. use the default ProductDistribution factory)
        # once Spree's calculators are compatible with LineItem targets, not just Orders.
        distributor = create(:distributor_enterprise)
        enterprise_fee = create(:enterprise_fee, enterprise: distributor, calculator: build(:calculator))
        pd = create(:product_distribution, distributor: distributor, enterprise_fee: enterprise_fee)

        pd.stub(:adjustment_label) { 'label' }
        line_item = create(:line_item)

        expect { pd.send(:create_adjustment_on, line_item) }.to change(Spree::Adjustment, :count).by(1)

        adjustment = Spree::Adjustment.last
        adjustment.label.should == 'label'
        adjustment.adjustable.should == line_item
        adjustment.source.should == enterprise_fee
        adjustment.originator.should == enterprise_fee
        adjustment.should be_mandatory
      end
    end
  end
end
