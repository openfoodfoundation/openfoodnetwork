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

  describe "reporting whether it is an incoming exchange" do
    let(:supplier) { create(:supplier_enterprise) }
    let(:coordinator) { create(:distributor_enterprise) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:oc) { create(:simple_order_cycle, coordinator: coordinator) }

    let(:incoming_exchange) { oc.exchanges.create! sender: supplier,    receiver: coordinator }
    let(:outgoing_exchange) { oc.exchanges.create! sender: coordinator, receiver: distributor }

    it "returns true for incoming exchanges" do
      incoming_exchange.should be_incoming
    end

    it "returns false for outgoing exchanges" do
      outgoing_exchange.should_not be_incoming
    end
  end

  describe "reporting its role" do
    it "returns 'supplier' when it is an incoming exchange" do
      e = Exchange.new
      e.stub(:incoming?) { true }
      e.role.should == 'supplier'
    end

    it "returns 'distributor' when it is an outgoing exchange" do
      e = Exchange.new
      e.stub(:incoming?) { false }
      e.role.should == 'distributor'
    end
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

    it "finds exchanges going to any of a number of enterprises" do
      Exchange.to_enterprises([coordinator]).should == [incoming_exchange]
      Exchange.to_enterprises([coordinator, distributor]).sort.should == [incoming_exchange, outgoing_exchange].sort
    end

    it "finds exchanges coming from any of a number of enterprises" do
      Exchange.from_enterprises([coordinator]).should == [outgoing_exchange]
      Exchange.from_enterprises([supplier, coordinator]).sort.should == [incoming_exchange, outgoing_exchange].sort
    end

    it "finds exchanges with a particular variant" do
      v = create(:variant)
      ex = create(:exchange)
      ex.variants << v

      Exchange.with_variant(v).should == [ex]
    end

    it "finds exchanges with any of a number of variants, without returning duplicates" do
      v1 = create(:variant)
      v2 = create(:variant)
      v3 = create(:variant)
      ex = create(:exchange)
      ex.variants << v1
      ex.variants << v2

      Exchange.with_any_variant([v1, v2, v3]).should == [ex]
    end

    it "finds exchanges with a particular product's master variant" do
      p = create(:simple_product)
      ex = create(:exchange)
      ex.variants << p.master
      p.reload

      Exchange.with_product(p).should == [ex]
    end

    it "finds exchanges with a particular product's non-master variant" do
      p = create(:simple_product)
      v = create(:variant, product: p)
      ex = create(:exchange)
      ex.variants << v
      p.reload

      Exchange.with_product(p).should == [ex]
    end
  end

  it "clones itself" do
    oc = create(:order_cycle)
    new_oc = create(:simple_order_cycle)

    ex1 = oc.exchanges.last
    ex2 = ex1.clone! new_oc

    ex1.eql?(ex2).should be_true
  end

  describe "converting to hash" do
    let(:oc) { create(:order_cycle) }
    let(:exchange) do
      exchange = oc.exchanges.last
      exchange.payment_enterprise = Enterprise.last
      exchange.save!
      exchange.stub(:variant_ids) { [1835, 1834] } # Test id ordering
      exchange.stub(:enterprise_fee_ids) { [1493, 1492] } # Test id ordering
      exchange
    end

    it "converts to a hash" do
      exchange.to_h.should ==
        {'id' => exchange.id, 'order_cycle_id' => oc.id,
        'sender_id' => exchange.sender_id, 'receiver_id' => exchange.receiver_id,
        'payment_enterprise_id' => exchange.payment_enterprise_id, 'variant_ids' => exchange.variant_ids.sort,
        'enterprise_fee_ids' => exchange.enterprise_fee_ids.sort,
        'pickup_time' => exchange.pickup_time, 'pickup_instructions' => exchange.pickup_instructions,
        'created_at' => exchange.created_at, 'updated_at' => exchange.updated_at}
    end

    it "converts to a hash of core attributes only" do
      exchange.to_h(true).should ==
        {'sender_id' => exchange.sender_id, 'receiver_id' => exchange.receiver_id,
         'payment_enterprise_id' => exchange.payment_enterprise_id, 'variant_ids' => exchange.variant_ids.sort,
         'enterprise_fee_ids' => exchange.enterprise_fee_ids.sort,
         'pickup_time' => exchange.pickup_time, 'pickup_instructions' => exchange.pickup_instructions}
    end
  end

  describe "comparing equality" do
    it "compares Exchanges using to_h" do
      e1 = Exchange.new
      e2 = Exchange.new

      e1.stub(:to_h) { {'sender_id' => 456} }
      e2.stub(:to_h) { {'sender_id' => 456} }

      e1.eql?(e2).should be_true
    end

    it "compares other objects using super" do
      exchange = Exchange.new
      exchange_fee = ExchangeFee.new

      exchange.eql?(exchange_fee).should be_false
    end
  end
end
