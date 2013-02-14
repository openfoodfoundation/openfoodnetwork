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

  context "validating distributor changes" do
    it "checks that a distributor is available when changing" do
      order_enterprise = FactoryGirl.create(:enterprise, id: 1, :name => "Order Enterprise")
      subject.distributor = order_enterprise
      product1 = FactoryGirl.create(:product)
      product2 = FactoryGirl.create(:product)
      product3 = FactoryGirl.create(:product)
      variant11 = FactoryGirl.create(:variant, product: product1)
      variant12 = FactoryGirl.create(:variant, product: product1)
      variant21 = FactoryGirl.create(:variant, product: product2)
      variant31 = FactoryGirl.create(:variant, product: product3)
      variant32 = FactoryGirl.create(:variant, product: product3)

      # Product Distributions
      # Order Enterprise sells product 1 and product 3
      FactoryGirl.create(:product_distribution, product: product1, distributor: order_enterprise)
      FactoryGirl.create(:product_distribution, product: product3, distributor: order_enterprise)

      # Build the current order
      line_item1 = FactoryGirl.create(:line_item, order: subject, variant: variant11)
      line_item2 = FactoryGirl.create(:line_item, order: subject, variant: variant12)
      line_item3 = FactoryGirl.create(:line_item, order: subject, variant: variant31)
      subject.reload
      subject.line_items = [line_item1,line_item2,line_item3]

      test_enterprise = FactoryGirl.create(:enterprise, id: 2, :name => "Test Enterprise")
      # Test Enterprise sells only product 1
      FactoryGirl.create(:product_distribution, product: product1, distributor: test_enterprise)

      subject.distributor = test_enterprise
      subject.should_not be_valid
      subject.errors.should include :distributor_id
    end
  end
end
