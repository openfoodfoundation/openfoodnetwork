require 'spec_helper'

describe Spree::Order do
  it "provides permissions for changing distributor" do
    p = build(:product)

    subject.can_change_distributor?.should be_true
    subject.add_variant(p.master, 1)
    subject.can_change_distributor?.should be_false
  end
end
