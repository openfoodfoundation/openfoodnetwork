require 'open_food_web/distributor_change_validator'

describe DistributorChangeValidator do
  let(:order) { double(:order) }
  let(:subject) { DistributorChangeValidator.new(order) }
  
  context "permissions for changing distributor" do
    it "allows distributor to be changed if line_items is empty" do
      order.stub(:line_items) { [] }
      subject.can_change_distributor?.should be_true
    end
    
    it "does not allow distributor to be changed if line_items is not empty" do
      order.stub(:line_items) { [1, 2, 3] }
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
      enterprise.stub(:available_variants){ line_item_variants } # Exactly the same variants as the order

      subject.available_distributors([enterprise]).should == [enterprise]
    end

    it "does not match enterprises with no products available" do
      variant1 = double(:variant)
      variant3 = double(:variant)
      variant5 = double(:variant)
      line_item_variants = [variant1, variant3, variant5]
      order.stub(:line_item_variants){ line_item_variants }
      enterprise = double(:enterprise)
      enterprise.stub(:available_variants){ [] } # No variants

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
      enterprise_with_some_variants.stub(:available_variants){ [variant1, variant3] } # Only some variants
      enterprise_with_some_plus_extras = double(:enterprise)
      enterprise_with_some_plus_extras.stub(:available_variants){ [variant1, variant2, variant3, variant4] } # Only some variants, plus extras
      
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
      enterprise.stub(:available_variants){ [variant1, variant2, variant3, variant4, variant5] } # Excess variants
      
      subject.available_distributors([enterprise]).should == [enterprise]
    end
    
    it "matches no enterprises when none are provided" do
      subject.available_distributors([]).should == []
    end
  end

  it "can fail" do
    fail
  end
end
