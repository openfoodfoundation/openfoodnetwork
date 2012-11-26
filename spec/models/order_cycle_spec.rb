require 'spec_helper'

describe OrderCycle do
  it "should be valid when built from factory" do
    build(:order_cycle).should be_valid
  end

  it "should not be valid without a name" do
    oc = build(:order_cycle)
    oc.name = ''
    oc.should_not be_valid
  end

  it "has a coordinator and associated fees" do
    oc = create(:order_cycle)

    oc.coordinator = create(:enterprise)
    oc.coordinator_admin_fee = create(:enterprise_fee)
    oc.coordinator_sales_fee = create(:enterprise_fee)

    oc.save!
  end

  it "has exchanges" do
    oc = create(:order_cycle)

    create(:exchange, :order_cycle => oc)
    create(:exchange, :order_cycle => oc)
    create(:exchange, :order_cycle => oc)

    oc.exchanges.count.should == 3
  end
end
