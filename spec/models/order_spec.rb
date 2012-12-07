require 'spec_helper'

describe Spree::Order do
  it "initialises a default shipping method after creation" do
    shipping_method_back_end = create(:shipping_method, :display_on => :back_end)
    shipping_method_both = create(:shipping_method, :display_on => :both)

    subject.shipping_method.should be_nil
    subject.adjustments.should be_empty

    subject.save!

    subject.shipping_method.should == shipping_method_both
    subject.adjustments.where(:label => "Shipping").should be_present
  end

  it "reveals permission for changing distributor" do
    d = create(:distributor_enterprise)
    p = create(:product, :distributors => [d])

    subject.distributor = d
    subject.save!

    subject.can_change_distributor?.should be_true
    subject.add_variant(p.master, 1)
    subject.can_change_distributor?.should be_false
  end

  it "checks that distributor is available when changing, and raises an exception if distributor is changed without permission" do
    d = create(:distributor_enterprise)
    p = create(:product, :distributors => [d])
    subject.distributor = d
    subject.save!

    subject.add_variant(p.master, 1)
    subject.can_change_distributor?.should be_false
    subject.should_receive(:available_distributors)

    expect do
      subject.distributor = nil
    end.to raise_error "You cannot change the distributor of an order with products"
  end

  it "reveals permission for adding products to the cart" do
    d1 = create(:distributor_enterprise)
    d2 = create(:distributor_enterprise)

    p_first = create(:product, :distributors => [d1])
    p_subsequent_same_dist = create(:product, :distributors => [d1])
    p_subsequent_other_dist = create(:product, :distributors => [d2])

    # We need to set distributor, since order.add_variant does not, and
    # we also need to save the order so that line items can be added to
    # the association.
    subject.distributor = d1
    subject.save!

    # The first product in the cart can be added
    subject.can_add_product_to_cart?(p_first).should be_true
    subject.add_variant(p_first.master, 1)

    # A subsequent product can be added if the distributor matches
    subject.can_add_product_to_cart?(p_subsequent_same_dist).should be_true
    subject.add_variant(p_subsequent_same_dist.master, 1)

    # And cannot be added if it does not match
    subject.can_add_product_to_cart?(p_subsequent_other_dist).should be_false
  end

  it "sets attributes on line items for variants" do
    d = create(:distributor_enterprise)
    p = create(:product, :distributors => [d])

    subject.distributor = d
    subject.save!

    subject.add_variant(p.master, 1)
    subject.set_variant_attributes(p.master, {'max_quantity' => '3'})

    li = Spree::LineItem.last
    li.max_quantity.should == 3
  end

  context "finding alternative distributors" do
    it "checks that variants are available" do
      distributors_with_all_variants = double(:distributors_with_all_variants)
      subject.should_receive(:get_distributors_with_all_variants).with(Enterprise.all)
      subject.available_distributors
    end

    context "finding distributors which have the same variants" do
      before(:each) do
        @enterprise1 = FactoryGirl.create(:enterprise, id: 1)
        subject.distributor = @enterprise1
        @product1 = FactoryGirl.create(:product)
        @product2 = FactoryGirl.create(:product)
        @product3 = FactoryGirl.create(:product)
        variant11 = FactoryGirl.create(:variant, product: @product1)
        variant12 = FactoryGirl.create(:variant, product: @product1)
        variant21 = FactoryGirl.create(:variant, product: @product2)
        variant31 = FactoryGirl.create(:variant, product: @product3)
        variant32 = FactoryGirl.create(:variant, product: @product3)

        # Product Distributions
        # Enterprise 1 sells product 1 and product 3
        FactoryGirl.create(:product_distribution, product: @product1, distributor: @enterprise1)
        FactoryGirl.create(:product_distribution, product: @product3, distributor: @enterprise1)

        # Build the current order
        line_item1 = FactoryGirl.create(:line_item, order: subject, variant: variant11)
        line_item2 = FactoryGirl.create(:line_item, order: subject, variant: variant12)
        line_item3 = FactoryGirl.create(:line_item, order: subject, variant: variant31)
        subject.line_items = [line_item1,line_item2,line_item3]
      end

      it "matches the distributor enterprise of the current order" do
        subject.get_distributors_with_all_variants([@enterprise1]).should == [@enterprise1]
      end

      it "does not match enterprises with no products available" do
        test_enterprise = FactoryGirl.create(:enterprise, id: 2)
        subject.get_distributors_with_all_variants([@enterprise1, test_enterprise]).should_not include test_enterprise
      end

      it "does not match enterprises with only some of the same variants in the current order available" do
        test_enterprise = FactoryGirl.create(:enterprise, id: 2)
        # Test Enterprise sells only product 1
        FactoryGirl.create(:product_distribution, product: @product1, distributor: test_enterprise)
        subject.get_distributors_with_all_variants([@enterprise1, test_enterprise]).should_not include test_enterprise
      end

      it "matches enteprises which offer all products in the current order" do
        test_enterprise = FactoryGirl.create(:enterprise, id: 2)
        # Enterprise 3 Sells Products 1, 2 and 3
        FactoryGirl.create(:product_distribution, product: @product1, distributor: test_enterprise)
        FactoryGirl.create(:product_distribution, product: @product2, distributor: test_enterprise)
        FactoryGirl.create(:product_distribution, product: @product3, distributor: test_enterprise)
        subject.get_distributors_with_all_variants([@enterprise1, test_enterprise]).should include test_enterprise
     end
    end
  end
end
