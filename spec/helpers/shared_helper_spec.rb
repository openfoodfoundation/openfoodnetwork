require 'spec_helper'

describe SharedHelper do

  it "does not require emptying the cart when it is empty" do
    d = double(:distributor)
    order = double(:order, line_items: [])
    helper.stub(:current_order) { order }
    helper.distributor_link_class(d).should_not =~ /empties-cart/
  end

  it "does not require emptying the cart when we are on the same distributor" do
    d = double(:distributor)
    order = double(:order, line_items: [double(:line_item)], distributor: d)
    helper.stub(:current_order) { order }
    helper.distributor_link_class(d).should_not =~ /empties-cart/
  end

  it "requires emptying the cart otherwise" do
    d1 = double(:distributor)
    d2 = double(:distributor)
    order = double(:order, line_items: [double(:line_item)], distributor: d2)
    helper.stub(:current_order) { order }
    helper.distributor_link_class(d1).should =~ /empties-cart/
  end

  describe "finding current producers" do
    it "finds producers for the current distribution" do
      s = create(:supplier_enterprise)
      d = create(:distributor_enterprise)
      p = create(:simple_product)
      oc = create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])

      helper.stub(:current_order_cycle) { oc }
      helper.stub(:current_distributor) { d }

      helper.current_producers.should == [s]
    end

    it "returns [] when no order cycle set" do
      d = double(:distributor)

      helper.stub(:current_order_cycle) { nil }
      helper.stub(:current_distributor) { d }

      helper.current_producers.should == []
    end

    it "returns [] when no distributor set" do
      oc = double(:order_cycle)

      helper.stub(:current_order_cycle) { oc }
      helper.stub(:current_distributor) { nil }

      helper.current_producers.should == []

    end
  end
end
