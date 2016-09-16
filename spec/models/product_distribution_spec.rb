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
        pending "Intermittently failing spec - we intend to remove product distributions soon"

        # Given an order
        distributor = create(:distributor_enterprise)
        order = create(:order, distributor: distributor)

        # And a product with a product distribution with an enterprise fee
        product = create(:product, name: 'Pear')
        enterprise_fee = create(:enterprise_fee, calculator: build(:calculator))
        enterprise_fee.calculator.preferred_amount = 1.23
        enterprise_fee.calculator.save!
        create(:product_distribution, product: product, distributor: distributor, enterprise_fee: enterprise_fee)

        # When I add the product to the order, an adjustment should be made
        expect do
          op = Spree::OrderPopulator.new order, 'AU'
          op.populate products: {product.id => product.master.id}, quantity: 1, distributor_id: distributor.id

          # Normally the controller would fire this event when the order's contents are changed
          fire_order_contents_changed_event(order.user, order)
        end.to change(Spree::Adjustment, :count).by(1)

        # And it should have the correct data
        order.reload
        adjustments = order.adjustments.where(:originator_type => 'EnterpriseFee')
        adjustments.count.should == 1
        adjustment = adjustments.first

        adjustment.source.should == order.line_items.last
        adjustment.originator.should == enterprise_fee
        adjustment.label.should == "Product distribution by #{distributor.name} for Pear"
        adjustment.amount.should == 1.23

        # TODO ROB this has an intermittent failure
        # And it should have some associated metadata
        md = adjustment.metadata
        md.enterprise.should == distributor
        md.fee_name.should == enterprise_fee.name
        md.fee_type.should == enterprise_fee.fee_type
        md.enterprise_role.should == 'distributor'
      end
    end

    describe "finding our adjustment for a line item" do
      it "returns nil when not present" do
        line_item = build(:line_item)
        pd = ProductDistribution.new
        pd.send(:adjustment_for, line_item).should be_nil
      end

      it "returns the adjustment when present" do
        pd = create(:product_distribution)
        line_item = create(:line_item)
        adjustment = pd.enterprise_fee.create_adjustment('foo', line_item.order, line_item, true)

        pd.send(:adjustment_for, line_item).should == adjustment
      end

      it "raises an error when there are multiple adjustments for this enterprise fee" do
        pd = create(:product_distribution)
        line_item = create(:line_item)
        pd.enterprise_fee.create_adjustment('one', line_item.order, line_item, true)
        pd.enterprise_fee.create_adjustment('two', line_item.order, line_item, true)

        expect do
          pd.send(:adjustment_for, line_item)
        end.to raise_error "Multiple adjustments for this enterprise fee on this line item. This method is not designed to deal with this scenario."
      end
    end

    describe "creating an adjustment for a line item" do
      it "creates the adjustment via the enterprise fee" do
        pd = create(:product_distribution)
        pd.stub(:adjustment_label_for) { 'label' }
        line_item = create(:line_item)

        expect { pd.send(:create_adjustment_for, line_item) }.to change(Spree::Adjustment, :count).by(1)

        adjustment = Spree::Adjustment.last
        adjustment.label.should == 'label'
        adjustment.adjustable.should == line_item.order
        adjustment.source.should == line_item
        adjustment.originator.should == pd.enterprise_fee
        adjustment.should be_mandatory

        md = adjustment.metadata
        md.enterprise.should == pd.distributor
        md.fee_name.should == pd.enterprise_fee.name
        md.fee_type.should == pd.enterprise_fee.fee_type
        md.enterprise_role.should == 'distributor'
      end
    end
  end


  private

  def fire_order_contents_changed_event(user, order)
    ActiveSupport::Notifications.instrument('spree.order.contents_changed', {user: user, order: order})
  end

end
