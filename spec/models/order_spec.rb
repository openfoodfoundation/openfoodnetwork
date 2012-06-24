require 'spec_helper'

describe Spree::Order do
  it "reveals permission for changing distributor" do
    p = build(:product)

    subject.can_change_distributor?.should be_true
    subject.add_variant(p.master, 1)
    subject.can_change_distributor?.should be_false
  end

  it "raises an exception if distributor is changed without permission" do
    p = build(:product)
    subject.add_variant(p.master, 1)
    subject.can_change_distributor?.should be_false

    expect do
      subject.distributor = nil
    end.to raise_error "You cannot change the distributor of an order with products"
  end
end
