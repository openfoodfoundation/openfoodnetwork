require 'open_food_web/distributor_change_validator'

describe DistributorChangeValidator do
  let(:order) { double(:order) }
  let(:subject) { DistributorChangeValidator.new(order) }
  let(:product) { double(:product) }

  context "permissions for changing distributor" do
    it "allows distributor to be changed if line_items is empty" do
      order.stub(:line_items) { [] }
      subject.can_change_distributor?.should be_true
    end
    
    it "allows distributor to be changed if there are multiple available distributors" do
      order.stub(:line_items) { [1, 2, 3] }
      subject.stub(:available_distributors).and_return([1, 2])
      subject.can_change_distributor?.should be_true
    end

    it "does not allow distributor to be changed if there are no other available distributors" do
      order.stub(:line_items) { [1, 2, 3] }
      subject.stub(:available_distributors).and_return([1])
      subject.can_change_distributor?.should be_false
    end
  end
  
  context "finding distributors which have the same variants" do
    it "matches enterprises which offer all products within the order" do
      variant1 = double(:variant)
      variant2 = double(:variant)
      variant3 = double(:variant)
      variant5 = double(:variant)
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants){ line_item_variants }
      enterprise = double(:enterprise)
      enterprise.stub(:distributed_variants){ line_item_variants } # Exactly the same variants as the order

      subject.available_distributors([enterprise]).should == [enterprise]
    end

    it "does not match enterprises with no products available" do
      variant1 = double(:variant)
      variant3 = double(:variant)
      variant5 = double(:variant)
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants){ line_item_variants }
      enterprise = double(:enterprise)
      enterprise.stub(:distributed_variants){ [] } # No variants

      subject.available_distributors([enterprise]).should_not include enterprise
    end

    it "does not match enterprises with only some of the same variants in the order available" do
      variant1 = double(:variant)
      variant2 = double(:variant)
      variant3 = double(:variant)
      variant4 = double(:variant)
      variant5 = double(:variant)
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants){ line_item_variants }
      enterprise_with_some_variants = double(:enterprise)
      enterprise_with_some_variants.stub(:distributed_variants){ [variant1, variant3] } # Only some variants
      enterprise_with_some_plus_extras = double(:enterprise)
      enterprise_with_some_plus_extras.stub(:distributed_variants){ [variant1, variant2, variant3, variant4] } # Only some variants, plus extras
      
      subject.available_distributors([enterprise_with_some_variants]).should_not include enterprise_with_some_variants
      subject.available_distributors([enterprise_with_some_plus_extras]).should_not include enterprise_with_some_plus_extras
    end

    it "matches enteprises which offer all products in the order, plus additional products" do
      variant1 = double(:variant)
      variant2 = double(:variant)
      variant3 = double(:variant)
      variant4 = double(:variant)
      variant5 = double(:variant)
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants){ line_item_variants }
      enterprise = double(:enterprise)
      enterprise.stub(:distributed_variants){ [variant1, variant2, variant3, variant4, variant5] } # Excess variants
      
      subject.available_distributors([enterprise]).should == [enterprise]
    end
    
    it "matches no enterprises when none are provided" do
      subject.available_distributors([]).should == []
    end
  end

  describe "checking product compatibility with current order" do
    it "returns true when order is nil" do
      subject = DistributorChangeValidator.new(nil)
      subject.product_compatible_with_current_order(product).should be_true
    end

    it "returns true when there's an distributor that can cover the new product" do
      subject.stub(:available_distributors_for).and_return([1])
      subject.product_compatible_with_current_order(product).should be_true
    end

    it "returns false when there's no distributor that can cover the new product" do
      subject.stub(:available_distributors_for).and_return([])
      subject.product_compatible_with_current_order(product).should be_false
    end
  end

  describe "finding available distributors for a product" do
    it "returns enterprises distributing the product when there's no order" do
      subject = DistributorChangeValidator.new(nil)
      Enterprise.stub(:distributing_product).and_return([1, 2, 3])
      subject.should_receive(:available_distributors).never

      subject.available_distributors_for(product).should == [1, 2, 3]
    end

    it "returns enterprises distributing the product when there's no order items" do
      order.stub(:line_items) { [] }
      Enterprise.stub(:distributing_product).and_return([1, 2, 3])
      subject.should_receive(:available_distributors).never

      subject.available_distributors_for(product).should == [1, 2, 3]
    end

    it "filters by available distributors when there are order items" do
      order.stub(:line_items) { [1, 2, 3] }
      Enterprise.stub(:distributing_product).and_return([1, 2, 3])
      subject.should_receive(:available_distributors).and_return([2])

      subject.available_distributors_for(product).should == [2]
    end
  end
end
