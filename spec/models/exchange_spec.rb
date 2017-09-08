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

  it "should not be valid when (sender, receiver, direction) set are not unique for its order cycle" do
    e1 = create(:exchange)

    e2 = build(:exchange,
               :order_cycle => e1.order_cycle, :sender => e1.sender, :receiver => e1.receiver, :incoming => e1.incoming)
    e2.should_not be_valid

    e2.incoming = !e2.incoming
    e2.should be_valid
    e2.incoming = !e2.incoming

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

  describe "exchange directionality" do
    let(:supplier) { create(:supplier_enterprise) }
    let(:coordinator) { create(:distributor_enterprise) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:oc) { create(:simple_order_cycle, coordinator: coordinator) }
    let(:incoming_exchange) { oc.exchanges.create! sender: supplier, receiver: coordinator, incoming: true }
    let(:outgoing_exchange) { oc.exchanges.create! sender: coordinator, receiver: distributor, incoming: false }

    describe "reporting whether it is an incoming exchange" do
      it "returns true for incoming exchanges" do
        incoming_exchange.should be_incoming
      end

      it "returns false for outgoing exchanges" do
        outgoing_exchange.should_not be_incoming
      end
    end

    describe "finding the exchange participant (the enterprise other than the coordinator)" do
      it "returns the sender for incoming exchanges" do
        incoming_exchange.participant.should == supplier
      end

      it "returns the receiver for outgoing exchanges" do
        outgoing_exchange.participant.should == distributor
      end
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

  describe "products caching" do
    let!(:exchange) { create(:exchange) }

    it "refreshes the products cache on change" do
      expect(OpenFoodNetwork::ProductsCache).to receive(:exchange_changed).with(exchange)
      exchange.pickup_time = 'asdf'
      exchange.save
    end

    it "refreshes the products cache on destruction" do
      expect(OpenFoodNetwork::ProductsCache).to receive(:exchange_destroyed).with(exchange)
      exchange.destroy
    end
  end

  describe "scopes" do
    let(:supplier) { create(:supplier_enterprise) }
    let(:coordinator) { create(:distributor_enterprise, is_primary_producer: true) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:oc) { create(:simple_order_cycle, coordinator: coordinator) }

    describe "finding exchanges managed by a particular user" do
      let(:user) do
        user = create(:user)
        user.spree_roles = []
        user
      end

      before { Exchange.destroy_all }

      it "returns exchanges where the user manages both the sender and the receiver" do
        exchange = create(:exchange, order_cycle: oc)
        exchange.sender.users << user
        exchange.receiver.users << user

        Exchange.managed_by(user).should == [exchange]
      end

      it "does not return exchanges where the user manages only the sender" do
        exchange = create(:exchange, order_cycle: oc)
        exchange.sender.users << user

        Exchange.managed_by(user).should be_empty
      end

      it "does not return exchanges where the user manages only the receiver" do
        exchange = create(:exchange, order_cycle: oc)
        exchange.receiver.users << user

        Exchange.managed_by(user).should be_empty
      end

      it "does not return exchanges where the user manages neither enterprise" do
        exchange = create(:exchange, order_cycle: oc)
        Exchange.managed_by(user).should be_empty
      end
    end

    it "finds exchanges in a particular order cycle" do
      ex = create(:exchange, order_cycle: oc)
      Exchange.in_order_cycle(oc).should == [ex]
    end

    describe "finding exchanges by direction" do
      let!(:incoming_exchange) { oc.exchanges.create! sender: supplier,    receiver: coordinator, incoming: true }
      let!(:outgoing_exchange) { oc.exchanges.create! sender: coordinator, receiver: distributor, incoming: false }

      it "finds incoming exchanges" do
        Exchange.incoming.should == [incoming_exchange]
      end

      it "finds outgoing exchanges" do
        Exchange.outgoing.should == [outgoing_exchange]
      end

      it "correctly determines direction of exchanges between the same enterprise" do
        incoming_exchange.update_attributes sender: coordinator, incoming: true
        outgoing_exchange.update_attributes receiver: coordinator, incoming: false
        Exchange.incoming.should == [incoming_exchange]
        Exchange.outgoing.should == [outgoing_exchange]
      end

      it "finds exchanges coming from an enterprise" do
        Exchange.from_enterprise(supplier).should    == [incoming_exchange]
        Exchange.from_enterprise(coordinator).should == [outgoing_exchange]
      end

      it "finds exchanges going to an enterprise" do
        Exchange.to_enterprise(coordinator).should == [incoming_exchange]
        Exchange.to_enterprise(distributor).should == [outgoing_exchange]
      end

      it "finds exchanges coming from any of a number of enterprises" do
        Exchange.from_enterprises([coordinator]).should == [outgoing_exchange]
        Exchange.from_enterprises([supplier, coordinator]).should match_array [incoming_exchange, outgoing_exchange]
      end

      it "finds exchanges going to any of a number of enterprises" do
        Exchange.to_enterprises([coordinator]).should == [incoming_exchange]
        Exchange.to_enterprises([coordinator, distributor]).should match_array [incoming_exchange, outgoing_exchange]
      end

      it "finds exchanges involving any of a number of enterprises" do
        Exchange.involving([supplier]).should == [incoming_exchange]
        Exchange.involving([coordinator]).should match_array [incoming_exchange, outgoing_exchange]
        Exchange.involving([distributor]).should == [outgoing_exchange]
      end
    end

    describe "finding exchanges supplying to a distributor" do
      it "returns incoming exchanges" do
        d = create(:distributor_enterprise)
        ex = create(:exchange, order_cycle: oc, incoming: true)

        oc.exchanges.supplying_to(d).should == [ex]
      end

      it "returns outgoing exchanges to the distributor" do
        d = create(:distributor_enterprise)
        ex = create(:exchange, order_cycle: oc, receiver: d, incoming: false)

        oc.exchanges.supplying_to(d).should == [ex]
      end

      it "does not return outgoing exchanges to a different distributor" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        ex = create(:exchange, order_cycle: oc, receiver: d1, incoming: false)

        oc.exchanges.supplying_to(d2).should be_empty
      end
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

    describe "sorting exchanges by primary enterprise name" do
      let(:e1) { create(:supplier_enterprise,    name: 'ZZZ') }
      let(:e2) { create(:distributor_enterprise, name: 'AAA') }
      let(:e3) { create(:supplier_enterprise,    name: 'CCC') }

      let!(:ex1) { create(:exchange, sender:   e1, incoming: true) }
      let!(:ex2) { create(:exchange, receiver: e2, incoming: false) }
      let!(:ex3) { create(:exchange, sender:   e3, incoming: true) }

      it "sorts" do
        Exchange.by_enterprise_name.should == [ex2, ex3, ex1]
      end
    end
  end

  it "clones itself" do
    oc = create(:order_cycle)
    new_oc = create(:simple_order_cycle)

    ex1 = oc.exchanges.last
    ex1.update_attribute(:tag_list, "wholesale")
    ex2 = ex1.clone! new_oc

    ex1.eql?(ex2).should be true
    expect(ex2.reload.tag_list).to eq ["wholesale"]
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
        'incoming' => exchange.incoming,
        'payment_enterprise_id' => exchange.payment_enterprise_id, 'variant_ids' => exchange.variant_ids.sort,
        'enterprise_fee_ids' => exchange.enterprise_fee_ids.sort,
        'pickup_time' => exchange.pickup_time, 'pickup_instructions' => exchange.pickup_instructions,
        'receival_instructions' => exchange.receival_instructions,
        'created_at' => exchange.created_at, 'updated_at' => exchange.updated_at}
    end

    it "converts to a hash of core attributes only" do
      exchange.to_h(true).should ==
        {'sender_id' => exchange.sender_id, 'receiver_id' => exchange.receiver_id,
         'incoming' => exchange.incoming,
         'payment_enterprise_id' => exchange.payment_enterprise_id, 'variant_ids' => exchange.variant_ids.sort,
         'enterprise_fee_ids' => exchange.enterprise_fee_ids.sort,
         'pickup_time' => exchange.pickup_time, 'pickup_instructions' => exchange.pickup_instructions,
         'receival_instructions' => exchange.receival_instructions}
    end
  end

  describe "comparing equality" do
    it "compares Exchanges using to_h" do
      e1 = Exchange.new
      e2 = Exchange.new

      e1.stub(:to_h) { {'sender_id' => 456} }
      e2.stub(:to_h) { {'sender_id' => 456} }

      e1.eql?(e2).should be true
    end

    it "compares other objects using super" do
      exchange = Exchange.new
      exchange_fee = ExchangeFee.new

      exchange.eql?(exchange_fee).should be false
    end
  end
end
