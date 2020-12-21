# frozen_string_literal: true

require 'spec_helper'

describe SharedHelper, type: :helper do
  it "does not require emptying the cart when it is empty" do
    d = double(:distributor)
    order = double(:order, line_items: [])
    allow(helper).to receive(:current_order) { order }
    expect(helper.distributor_link_class(d)).not_to match(/empties-cart/)
  end

  it "does not require emptying the cart when we are on the same distributor" do
    d = double(:distributor)
    order = double(:order, line_items: [double(:line_item)], distributor: d)
    allow(helper).to receive(:current_order) { order }
    expect(helper.distributor_link_class(d)).not_to match(/empties-cart/)
  end

  it "requires emptying the cart otherwise" do
    d1 = double(:distributor)
    d2 = double(:distributor)
    order = double(:order, line_items: [double(:line_item)], distributor: d2)
    allow(helper).to receive(:current_order) { order }
    expect(helper.distributor_link_class(d1)).to match(/empties-cart/)
  end
end
