require 'spec_helper'

describe Exchange do
  it "should be valid when built from factory" do
    build(:exchange).should be_valid
  end

  [:order_cycle, :sender, :receiver].each do |attr|
    it "should not be valid without #{attr}" do
      e = build(:exchange)
      e.send("#{attr}=", nil)
      e.should_not be_valid
    end
  end

  it "should not be valid when sender and receiver pair are not unique for its order cycle" do
    e1 = create(:exchange)

    e2 = build(:exchange,
               :order_cycle => e1.order_cycle, :sender => e1.sender, :receiver => e1.receiver)
    e2.should_not be_valid

    e2.receiver = create(:enterprise)
    e2.should be_valid

    e2.sender = e2.receiver
    e2.receiver = e1.receiver
    e2.should be_valid
  end

  it "has exchange variants" do
    e = create(:exchange)
    p = create(:product)

    e.exchange_variants.create(:variant => p.master)
    e.variants.count.should == 1
  end

  it "has exchange fees" do
    e = create(:exchange)
    f = create(:enterprise_fee)

    e.exchange_fees.create(:enterprise_fee => f)
    e.enterprise_fees.count.should == 1
  end

  describe "scopes" do
    let(:supplier) { create(:supplier_enterprise) }
    let(:coordinator) { create(:distributor_enterprise) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:oc) { create(:simple_order_cycle, coordinator: coordinator) }

    let!(:incoming_exchange) { oc.exchanges.create! sender: supplier,    receiver: coordinator }
    let!(:outgoing_exchange) { oc.exchanges.create! sender: coordinator, receiver: distributor }

    it "finds incoming exchanges" do
      Exchange.incoming.should == [incoming_exchange]
    end

    it "finds outgoing exchanges" do
      Exchange.outgoing.should == [outgoing_exchange]
    end
  end
end
