require 'spec_helper'

describe SharedHelper, type: :helper do

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
end
