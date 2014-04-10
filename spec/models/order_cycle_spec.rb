require 'spec_helper'

describe OrderCycle do
  it "should be valid when built from factory" do
    build(:simple_order_cycle).should be_valid
  end

  it "should not be valid without a name" do
    oc = build(:simple_order_cycle)
    oc.name = ''
    oc.should_not be_valid
  end

  it "has a coordinator and associated fees" do
    oc = create(:simple_order_cycle)

    oc.coordinator = create(:enterprise)
    oc.coordinator_fees << create(:enterprise_fee, enterprise: oc.coordinator)

    oc.save!
  end

  it "has exchanges" do
    oc = create(:simple_order_cycle)

    create(:exchange, order_cycle: oc)
    create(:exchange, order_cycle: oc)
    create(:exchange, order_cycle: oc)

    oc.exchanges.count.should == 3
  end

  it "finds order cycles in various stages of their lifecycle" do
    oc_active = create(:simple_order_cycle, orders_open_at: 1.week.ago, orders_close_at: 1.week.from_now)
    oc_not_yet_open = create(:simple_order_cycle, orders_open_at: 1.week.from_now, orders_close_at: 2.weeks.from_now)
    oc_already_closed = create(:simple_order_cycle, orders_open_at: 2.weeks.ago, orders_close_at: 1.week.ago)
    oc_undated = create(:simple_order_cycle, orders_open_at: nil, orders_close_at: nil)

    OrderCycle.active.should == [oc_active]
    OrderCycle.inactive.sort.should == [oc_not_yet_open, oc_already_closed].sort
    OrderCycle.upcoming.should == [oc_not_yet_open]
    OrderCycle.closed.should == [oc_already_closed]
    OrderCycle.undated.should == [oc_undated]
  end

  it "finds order cycles accessible by a user" do
    e1 = create(:enterprise, is_primary_producer: true, is_distributor: true)
    e2 = create(:enterprise, is_primary_producer: true, is_distributor: true)
    user = create(:user, enterprises: [e2], spree_roles: [])
    user.spree_roles = []

    oc_coordinated = create(:simple_order_cycle, coordinator: e2)
    oc_sent = create(:simple_order_cycle, suppliers: [e2])
    oc_received = create(:simple_order_cycle, distributors: [e2])
    oc_not_accessible = create(:simple_order_cycle, coordinator: e1)

    OrderCycle.accessible_by(user).should include(oc_coordinated, oc_sent, oc_received)
    OrderCycle.accessible_by(user).should_not include(oc_not_accessible)
  end

  describe "finding order cycles distributing a product" do
    it "returns order cycles distributing the product's master variant" do
      p = create(:product)
      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle, distributors: [d], variants: [p.master])
      p.reload

      OrderCycle.distributing_product(p).should == [oc]
    end

    it "returns order cycles distributing another variant" do
      p = create(:product)
      v = create(:variant, product: p)
      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle, distributors: [d], variants: [v])
      p.reload

      OrderCycle.distributing_product(p).should == [oc]
    end

    it "does not return order cycles supplying but not distributing a product" do
      p = create(:product)
      s = create(:supplier_enterprise)
      oc = create(:simple_order_cycle)
      ex = create(:exchange, order_cycle: oc, sender: s, receiver: oc.coordinator, incoming: true)
      ex.variants << p.master
      p.reload

      OrderCycle.distributing_product(p).should == []
    end
  end

  it "finds the most recently closed order cycles" do
    oc1 = create(:order_cycle, orders_close_at: 2.hours.ago)
    oc2 = create(:order_cycle, orders_close_at: 1.hour.ago)
    oc3 = create(:order_cycle, orders_close_at: 1.hour.from_now)

    OrderCycle.most_recently_closed.should == [oc2, oc1]
  end

  it "finds the soonest opening order cycles" do
    oc1 = create(:order_cycle, orders_open_at: 1.weeks.from_now)
    oc2 = create(:order_cycle, orders_open_at: 2.hours.from_now)
    oc3 = create(:order_cycle, orders_open_at: 1.hour.ago)

    OrderCycle.soonest_opening.should == [oc2, oc1]
  end

  it "finds the soonest closing order cycles" do
    oc1 = create(:order_cycle, orders_close_at: 2.hours.ago)
    oc2 = create(:order_cycle, orders_close_at: 2.hour.from_now)
    oc3 = create(:order_cycle, orders_close_at: 1.hour.from_now)

    OrderCycle.soonest_closing.should == [oc3, oc2]
  end

  describe "finding order cycles with a particular distributor" do
    let(:c) { create(:supplier_enterprise) }
    let(:d) { create(:distributor_enterprise) }

    it "returns order cycles with that distributor" do
      oc = create(:simple_order_cycle, coordinator: c, distributors: [d])
      OrderCycle.with_distributor(d).should == [oc]
    end

    it "does not return order cycles with that enterprise as supplier" do
      oc = create(:simple_order_cycle, coordinator: c, suppliers: [d])
      OrderCycle.with_distributor(d).should == []
    end

    it "does not return order cycles without that distributor" do
      oc = create(:simple_order_cycle, coordinator: c)
      OrderCycle.with_distributor(d).should == []
    end
  end

  it "reports its suppliers" do
    oc = create(:simple_order_cycle)

    e1 = create(:exchange, incoming: true,
                order_cycle: oc, receiver: oc.coordinator, sender: create(:enterprise))
    e2 = create(:exchange, incoming: true,
                order_cycle: oc, receiver: oc.coordinator, sender: create(:enterprise))

    oc.suppliers.sort.should == [e1.sender, e2.sender].sort
  end

  it "reports its distributors" do
    oc = create(:simple_order_cycle)

    e1 = create(:exchange, incoming: false,
                order_cycle: oc, sender: oc.coordinator, receiver: create(:enterprise))
    e2 = create(:exchange, incoming: false,
                order_cycle: oc, sender: oc.coordinator, receiver: create(:enterprise))

    oc.distributors.sort.should == [e1.receiver, e2.receiver].sort
  end

  it "checks for existance of distributors" do
    oc = create(:simple_order_cycle)
    d1 = create(:distributor_enterprise)
    d2 = create(:distributor_enterprise)
    create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d1, incoming: false)

    oc.should have_distributor(d1)
    oc.should_not have_distributor(d2)
  end

  it "checks for variants" do
    p1 = create(:simple_product)
    p2 = create(:simple_product)
    oc = create(:simple_order_cycle, suppliers: [p1.supplier], variants: [p1.master])

    oc.should have_variant(p1.master)
    oc.should_not have_variant(p2.master)
  end

  describe "product exchanges" do
    before(:each) do
      @oc = create(:simple_order_cycle)

      @d1 = create(:enterprise)
      @d2 = create(:enterprise)

      @e0 = create(:exchange, incoming: true,
                  order_cycle: @oc, sender: create(:enterprise), receiver: @oc.coordinator)
      @e1 = create(:exchange, incoming: false,
                  order_cycle: @oc, sender: @oc.coordinator, receiver: @d1)
      @e2 = create(:exchange, incoming: false,
                  order_cycle: @oc, sender: @oc.coordinator, receiver: @d2)

      @p0 = create(:simple_product)
      @p1 = create(:simple_product)
      @p1_v_deleted = create(:variant, product: @p1, deleted_at: Time.now)
      @p2 = create(:simple_product)
      @p2_v = create(:variant, product: @p2)

      @e0.variants << @p0.master
      @e1.variants << @p1.master
      @e1.variants << @p2.master
      @e1.variants << @p2_v
      @e2.variants << @p1.master
      @e2.variants << @p1_v_deleted
    end

    it "reports on the variants exchanged" do
      @oc.variants.sort.should == [@p0.master, @p1.master, @p2.master, @p2_v].sort
    end

    it "reports on the variants distributed" do
      @oc.distributed_variants.sort.should == [@p1.master, @p2.master, @p2_v].sort
    end

    it "reports on the variants distributed by a particular distributor" do
      @oc.variants_distributed_by(@d2).should == [@p1.master]
    end

    it "reports on the products distributed by a particular distributor" do
      @oc.products_distributed_by(@d2).should == [@p1]
    end

    it "reports on the products exchanged" do
      @oc.products.sort.should == [@p0, @p1, @p2]
    end
  end

  describe "finding valid products distributed by a particular distributor" do
    it "returns valid products but not invalid products" do
      p_valid = create(:product)
      p_invalid = create(:product)
      v = create(:variant, product: p_invalid)

      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle, distributors: [d], variants: [p_valid.master, p_invalid.master])
      oc.valid_products_distributed_by(d).should == [p_valid]
    end

    describe "checking if a product has only an obsolete master variant in a distributution" do
      it "returns true when so" do
        master = double(:master)
        unassociated_variant = double(:variant)
        product = double(:product, :has_variants? => true, :master => master, :variants => [])
        distributed_variants = [master, unassociated_variant]

        oc = OrderCycle.new
        oc.send(:product_has_only_obsolete_master_in_distribution?, product, distributed_variants).should be_true
      end

      it "returns false when the product doesn't have variants" do
        master = double(:master)
        product = double(:product, :has_variants? => false, :master => master, :variants => [])
        distributed_variants = [master]

        oc = OrderCycle.new
        oc.send(:product_has_only_obsolete_master_in_distribution?, product, distributed_variants).should be_false
      end

      it "returns false when the master isn't distributed" do
        master = double(:master)
        product = double(:product, :has_variants? => true, :master => master, :variants => [])
        distributed_variants = []

        oc = OrderCycle.new
        oc.send(:product_has_only_obsolete_master_in_distribution?, product, distributed_variants).should be_false
      end

      it "returns false when the product has other variants distributed" do
        master = double(:master)
        variant = double(:variant)
        product = double(:product, :has_variants? => true, :master => master, :variants => [variant])
        distributed_variants = [master, variant]

        oc = OrderCycle.new
        oc.send(:product_has_only_obsolete_master_in_distribution?, product, distributed_variants).should be_false
      end
    end
  end

  describe "exchanges" do
    before(:each) do
      @oc = create(:simple_order_cycle)

      @d1 = create(:enterprise)
      @d2 = create(:enterprise, next_collection_at: '2-8pm Friday')

      @e0 = create(:exchange, order_cycle: @oc, sender: create(:enterprise), receiver: @oc.coordinator, incoming: true)
      @e1 = create(:exchange, order_cycle: @oc, sender: @oc.coordinator, receiver: @d1, incoming: false, pickup_time: '5pm Tuesday', pickup_instructions: "Come get it!")
      @e2 = create(:exchange, order_cycle: @oc, sender: @oc.coordinator, receiver: @d2, incoming: false, pickup_time: nil)
    end

    it "finds the exchange for a distributor" do
      @oc.exchange_for_distributor(@d1).should == @e1
      @oc.exchange_for_distributor(@d2).should == @e2
    end

    describe "finding pickup time for a distributor" do
      it "looks up the pickup time on the exchange when present" do
        @oc.pickup_time_for(@d1).should == '5pm Tuesday'
      end

      it "returns the distributor's default collection time otherwise" do
        @oc.pickup_time_for(@d2).should == '2-8pm Friday'
      end
    end
    
    describe "finding pickup instructions for a distributor" do
      it "returns the pickup instructions" do
        @oc.pickup_instructions_for(@d1).should == "Come get it!"
      end
    end
  end

  describe "checking status" do
    let(:oc) { create(:order_cycle) }

    it "reports status when an order cycle is upcoming" do
      Timecop.freeze(oc.orders_open_at - 1.second) do
        oc.should_not be_undated
        oc.should     be_upcoming
        oc.should_not be_open
        oc.should_not be_closed
      end
    end

    it "reports status when an order cycle is open" do
      oc.should_not be_undated
      oc.should_not be_upcoming
      oc.should     be_open
      oc.should_not be_closed
    end

    it "reports status when an order cycle has closed" do
      Timecop.freeze(oc.orders_close_at + 1.second) do
        oc.should_not be_undated
        oc.should_not be_upcoming
        oc.should_not be_open
        oc.should     be_closed
      end
    end

    it "reports status when an order cycle is undated" do
      oc.update_attributes!(orders_open_at: nil, orders_close_at: nil)

      oc.should be_undated
      oc.should_not be_upcoming
      oc.should_not be_open
      oc.should_not be_closed
    end
  end

  it "clones itself" do
    oc = create(:order_cycle)
    occ = oc.clone!

    occ = OrderCycle.last
    occ.name.should == "COPY OF #{oc.name}"
    occ.orders_open_at.should be_nil
    occ.orders_close_at.should be_nil
    occ.coordinator.should == oc.coordinator

    occ.coordinator_fee_ids.should == oc.coordinator_fee_ids
    
    #(0..occ.exchanges.count).all? { |i| occ.exchanges[i].eql? oc.exchanges[i] }.should be_true
    
    # to_h gives us a unique hash for each exchange
    occ.exchanges.map(&:to_h).all? do |ex|
      oc.exchanges.map(&:to_h).include? ex
    end
  end

  describe "calculating fees for a variant via a particular distributor" do
    it "sums all the per-item fees for the variant in the specified hub + order cycle" do
      coordinator = create(:distributor_enterprise)
      distributor = create(:distributor_enterprise)
      order_cycle = create(:simple_order_cycle)
      enterprise_fee1 = create(:enterprise_fee, amount: 20)
      enterprise_fee2 = create(:enterprise_fee, amount:  3)
      enterprise_fee3 = create(:enterprise_fee,
                               calculator: Spree::Calculator::FlatRate.new(preferred_amount: 2))
      product = create(:simple_product)

      create(:exchange, order_cycle: order_cycle, sender: coordinator, receiver: distributor, incoming: false,
             enterprise_fees: [enterprise_fee1, enterprise_fee2, enterprise_fee3], variants: [product.master])
      
      order_cycle.fees_for(product.master, distributor).should == 23
    end


    it "sums percentage fees for the variant" do
      coordinator = create(:distributor_enterprise)
      distributor = create(:distributor_enterprise)
      order_cycle = create(:simple_order_cycle)
      enterprise_fee1 = create(:enterprise_fee, amount: 20, fee_type: "admin", calculator: Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 20))
      product = create(:simple_product, price: 10.00)
      
      create(:exchange, order_cycle: order_cycle, sender: coordinator, receiver: distributor, incoming: false,
             enterprise_fees: [enterprise_fee1], variants: [product.master])

      product.master.price.should == 10.00
      order_cycle.fees_for(product.master, distributor).should == 2.00
    end
  end

  describe "creating adjustments for a line item" do
    let(:oc) { OrderCycle.new }
    let(:variant) { double(:variant) }
    let(:distributor) { double(:distributor) }
    let(:order) { double(:order, distributor: distributor) }
    let(:line_item) { double(:line_item, variant: variant, order: order) }

    it "creates an adjustment for each fee" do
      applicator = double(:enterprise_fee_applicator)
      applicator.should_receive(:create_line_item_adjustment).with(line_item)
      oc.should_receive(:per_item_enterprise_fee_applicators_for).with(variant, distributor) { [applicator] }

      oc.send(:create_line_item_adjustments_for, line_item)
    end

    it "makes fee applicators for a line item" do
      distributor = double(:distributor)
      ef1 = double(:enterprise_fee)
      ef2 = double(:enterprise_fee)
      ef3 = double(:enterprise_fee)
      incoming_exchange = double(:exchange, role: 'supplier')
      outgoing_exchange = double(:exchange, role: 'distributor')
      incoming_exchange.stub_chain(:enterprise_fees, :per_item) { [ef1] }
      outgoing_exchange.stub_chain(:enterprise_fees, :per_item) { [ef2] }

      oc.stub(:exchanges_carrying) { [incoming_exchange, outgoing_exchange] }
      oc.stub_chain(:coordinator_fees, :per_item) { [ef3] }

      oc.send(:per_item_enterprise_fee_applicators_for, line_item.variant, distributor).should ==
        [OpenFoodNetwork::EnterpriseFeeApplicator.new(ef1, line_item.variant, 'supplier'),
         OpenFoodNetwork::EnterpriseFeeApplicator.new(ef2, line_item.variant, 'distributor'),
         OpenFoodNetwork::EnterpriseFeeApplicator.new(ef3, line_item.variant, 'coordinator')]
    end
  end

  describe "creating adjustments for an order" do
    let(:oc) { OrderCycle.new }
    let(:distributor) { double(:distributor) }
    let(:order) { double(:order, distributor: distributor) }

    it "creates an adjustment for each fee" do
      applicator = double(:enterprise_fee_applicator)
      applicator.should_receive(:create_order_adjustment).with(order)
      oc.should_receive(:per_order_enterprise_fee_applicators_for).with(order) { [applicator] }

      oc.send(:create_order_adjustments_for, order)
    end

    it "makes fee applicators for an order" do
      distributor = double(:distributor)
      ef1 = double(:enterprise_fee)
      ef2 = double(:enterprise_fee)
      ef3 = double(:enterprise_fee)
      incoming_exchange = double(:exchange, role: 'supplier')
      outgoing_exchange = double(:exchange, role: 'distributor')
      incoming_exchange.stub_chain(:enterprise_fees, :per_order) { [ef1] }
      outgoing_exchange.stub_chain(:enterprise_fees, :per_order) { [ef2] }

      oc.stub(:exchanges_supplying) { [incoming_exchange, outgoing_exchange] }
      oc.stub_chain(:coordinator_fees, :per_order) { [ef3] }

      oc.send(:per_order_enterprise_fee_applicators_for, order).should ==
        [OpenFoodNetwork::EnterpriseFeeApplicator.new(ef1, nil, 'supplier'),
         OpenFoodNetwork::EnterpriseFeeApplicator.new(ef2, nil, 'distributor'),
         OpenFoodNetwork::EnterpriseFeeApplicator.new(ef3, nil, 'coordinator')]
    end
  end

  describe "finding recently closed order cycles" do
    it "should give the most recently closed order cycle for a distributor" do
      distributor = create(:distributor_enterprise)
      oc = create(:simple_order_cycle, name: 'oc 1', distributors: [distributor], orders_open_at: 10.days.ago, orders_close_at: 9.days.ago)
      OrderCycle.most_recently_closed_for(distributor).should == oc
    end

    it "should return nil when there have been none" do
      distributor = create(:distributor_enterprise)
      OrderCycle.most_recently_closed_for(distributor).should == nil
    end
  end

  describe "finding order cycles opening in the future" do
    it "should give the soonest opening order cycle for a distributor" do
      distributor = create(:distributor_enterprise)
      oc = create(:simple_order_cycle, name: 'oc 1', distributors: [distributor], orders_open_at: 10.days.from_now, orders_close_at: 11.days.from_now) 
      OrderCycle.first_opening_for(distributor).should == oc
    end

    it "should return no order cycle when none are impending" do
      distributor = create(:distributor_enterprise)
      OrderCycle.first_opening_for(distributor).should == nil
    end
  end
end
