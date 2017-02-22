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

  describe "products cache" do
    let(:oc) { create(:open_order_cycle) }

    it "refreshes the products cache on save" do
      expect(OpenFoodNetwork::ProductsCache).to receive(:order_cycle_changed).with(oc)
      oc.name = 'asdf'
      oc.save
    end

    # On destroy, we're removing distributions, so no updates to the products cache are required
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
    oc_undated_open = create(:simple_order_cycle, orders_open_at: 1.week.ago, orders_close_at: nil)
    oc_undated_close = create(:simple_order_cycle, orders_open_at: nil, orders_close_at: 1.week.from_now)

    OrderCycle.active.should == [oc_active]
    OrderCycle.inactive.should match_array [oc_not_yet_open, oc_already_closed]
    OrderCycle.upcoming.should == [oc_not_yet_open]
    OrderCycle.closed.should == [oc_already_closed]
    OrderCycle.undated.should == [oc_undated, oc_undated_open, oc_undated_close]
    OrderCycle.not_closed.should == [oc_active, oc_not_yet_open, oc_undated, oc_undated_open, oc_undated_close]
    OrderCycle.dated.should == [oc_active, oc_not_yet_open, oc_already_closed]
  end

  it "finds order cycles accessible by a user" do
    e1 = create(:enterprise, is_primary_producer: true, sells: "any")
    e2 = create(:enterprise, is_primary_producer: true, sells: "any")
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
    oc1 = create(:simple_order_cycle, orders_close_at: 2.hours.ago)
    oc2 = create(:simple_order_cycle, orders_close_at: 1.hour.ago)
    oc3 = create(:simple_order_cycle, orders_close_at: 1.hour.from_now)

    OrderCycle.most_recently_closed.should == [oc2, oc1]
  end

  it "finds the soonest opening order cycles" do
    oc1 = create(:simple_order_cycle, orders_open_at: 1.weeks.from_now)
    oc2 = create(:simple_order_cycle, orders_open_at: 2.hours.from_now)
    oc3 = create(:simple_order_cycle, orders_open_at: 1.hour.ago)

    OrderCycle.soonest_opening.should == [oc2, oc1]
  end

  it "finds the soonest closing order cycles" do
    oc1 = create(:simple_order_cycle, orders_close_at: 2.hours.ago)
    oc2 = create(:simple_order_cycle, orders_close_at: 2.hour.from_now)
    oc3 = create(:simple_order_cycle, orders_close_at: 1.hour.from_now)

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

    oc.suppliers.should match_array [e1.sender, e2.sender]
  end

  it "reports its distributors" do
    oc = create(:simple_order_cycle)

    e1 = create(:exchange, incoming: false,
                order_cycle: oc, sender: oc.coordinator, receiver: create(:enterprise))
    e2 = create(:exchange, incoming: false,
                order_cycle: oc, sender: oc.coordinator, receiver: create(:enterprise))

    oc.distributors.should match_array [e1.receiver, e2.receiver]
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
    let(:oc) { create(:simple_order_cycle) }
    let(:d1) { create(:enterprise) }
    let(:d2) { create(:enterprise) }
    let!(:e0) { create(:exchange, incoming: true,
                order_cycle: oc, sender: create(:enterprise), receiver: oc.coordinator) }
    let!(:e1) { create(:exchange, incoming: false,
                order_cycle: oc, sender: oc.coordinator, receiver: d1) }
    let!(:e2) { create(:exchange, incoming: false,
                order_cycle: oc, sender: oc.coordinator, receiver: d2) }
    let!(:p0) { create(:simple_product) }
    let!(:p1) { create(:simple_product) }
    let!(:p1_v_deleted) { create(:variant, product: p1, deleted_at: Time.zone.now) }
    let!(:p1_v_visible) { create(:variant, product: p1, inventory_items: [create(:inventory_item, enterprise: d2, visible: true)]) }
    let!(:p1_v_hidden) { create(:variant, product: p1, inventory_items: [create(:inventory_item, enterprise: d2, visible: false)]) }
    let!(:p2) { create(:simple_product) }
    let!(:p2_v) { create(:variant, product: p2) }

    before(:each) do
      e0.variants << p0.master
      e1.variants << p1.master
      e1.variants << p2.master
      e1.variants << p2_v
      e2.variants << p1.master
      e2.variants << p1_v_deleted
      e2.variants << p1_v_visible
      e2.variants << p1_v_hidden
    end

    it "reports on the variants exchanged" do
      oc.variants.should match_array [p0.master, p1.master, p2.master, p2_v, p1_v_visible, p1_v_hidden]
    end

    it "returns the correct count of variants" do
      oc.variants.count.should == 6
    end

    it "reports on the variants supplied" do
      oc.supplied_variants.should match_array [p0.master]
    end

    it "reports on the variants distributed" do
      oc.distributed_variants.should match_array [p1.master, p2.master, p2_v, p1_v_visible, p1_v_hidden]
    end

    it "reports on the products distributed by a particular distributor" do
      oc.products_distributed_by(d2).should == [p1]
    end

    it "reports on the products exchanged" do
      oc.products.should match_array [p0, p1, p2]
    end

    context "listing variant distributed by a particular distributor" do
      context "when default settings are in play" do
        it "returns an empty list when no distributor is given" do
          oc.variants_distributed_by(nil).should == []
        end

        it "returns all variants in the outgoing exchange for the distributor provided" do
          oc.variants_distributed_by(d2).should include p1.master, p1_v_visible
          oc.variants_distributed_by(d2).should_not include p1_v_hidden, p1_v_deleted
          oc.variants_distributed_by(d1).should include p2_v
        end
      end

      context "when hub prefers product selection from inventory only" do
        before do
          allow(d1).to receive(:prefers_product_selection_from_inventory_only?) { true }
        end

        it "returns an empty list when no distributor is given" do
          oc.variants_distributed_by(nil).should == []
        end

        it "returns only variants in the exchange that are also in the distributor's inventory" do
          oc.variants_distributed_by(d1).should_not include p2_v
        end
      end
    end
  end

  describe "finding valid products distributed by a particular distributor" do
    it "returns valid products but not invalid products" do
      p_valid = create(:product)
      p_invalid = create(:product)
      v_valid = p_valid.variants.first
      v_invalid = p_invalid.variants.first

      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle, distributors: [d], variants: [v_valid, p_invalid.master])

      oc.valid_products_distributed_by(d).should == [p_valid]
    end

    describe "checking if a product has only an obsolete master variant in a distributution" do
      it "returns true when so" do
        master = double(:master)
        unassociated_variant = double(:variant)
        product = double(:product, :has_variants? => true, :master => master, :variants => [])
        distributed_variants = [master, unassociated_variant]

        oc = OrderCycle.new
        oc.send(:product_has_only_obsolete_master_in_distribution?, product, distributed_variants).should be true
      end

      it "returns false when the product doesn't have variants" do
        master = double(:master)
        product = double(:product, :has_variants? => false, :master => master, :variants => [])
        distributed_variants = [master]

        oc = OrderCycle.new
        oc.send(:product_has_only_obsolete_master_in_distribution?, product, distributed_variants).should be false
      end

      it "returns false when the master isn't distributed" do
        master = double(:master)
        product = double(:product, :has_variants? => true, :master => master, :variants => [])
        distributed_variants = []

        oc = OrderCycle.new
        oc.send(:product_has_only_obsolete_master_in_distribution?, product, distributed_variants).should be false
      end

      it "returns false when the product has other variants distributed" do
        master = double(:master)
        variant = double(:variant)
        product = double(:product, :has_variants? => true, :master => master, :variants => [variant])
        distributed_variants = [master, variant]

        oc = OrderCycle.new
        oc.send(:product_has_only_obsolete_master_in_distribution?, product, distributed_variants).should be false
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
    let(:oc) { create(:simple_order_cycle) }

    it "reports status when an order cycle is upcoming" do
      Timecop.freeze(oc.orders_open_at - 1.second) do
        oc.should_not be_undated
        oc.should     be_dated
        oc.should     be_upcoming
        oc.should_not be_open
        oc.should_not be_closed
      end
    end

    it "reports status when an order cycle is open" do
      oc.should_not be_undated
      oc.should     be_dated
      oc.should_not be_upcoming
      oc.should     be_open
      oc.should_not be_closed
    end

    it "reports status when an order cycle has closed" do
      Timecop.freeze(oc.orders_close_at + 1.second) do
        oc.should_not be_undated
        oc.should     be_dated
        oc.should_not be_upcoming
        oc.should_not be_open
        oc.should     be_closed
      end
    end

    it "reports status when an order cycle is undated" do
      oc.update_attributes!(orders_open_at: nil, orders_close_at: nil)

      oc.should     be_undated
      oc.should_not be_dated
      oc.should_not be_upcoming
      oc.should_not be_open
      oc.should_not be_closed
    end

    it "reports status when an order cycle is partially dated - opening time only" do
      oc.update_attributes!(orders_close_at: nil)

      oc.should     be_undated
      oc.should_not be_dated
      oc.should_not be_upcoming
      oc.should_not be_open
      oc.should_not be_closed
    end

    it "reports status when an order cycle is partially dated - closing time only" do
      oc.update_attributes!(orders_open_at: nil)

      oc.should     be_undated
      oc.should_not be_dated
      oc.should_not be_upcoming
      oc.should_not be_open
      oc.should_not be_closed
    end
  end

  it "clones itself" do
    coordinator = create(:enterprise);
    oc = create(:simple_order_cycle, coordinator_fees: [create(:enterprise_fee, enterprise: coordinator)], preferred_product_selection_from_coordinator_inventory_only: true)
    ex1 = create(:exchange, order_cycle: oc)
    ex2 = create(:exchange, order_cycle: oc)
    oc.clone!

    occ = OrderCycle.last
    occ.name.should == "COPY OF #{oc.name}"
    occ.orders_open_at.should be_nil
    occ.orders_close_at.should be_nil
    occ.coordinator.should_not be_nil
    occ.preferred_product_selection_from_coordinator_inventory_only.should be true
    occ.coordinator.should == oc.coordinator

    occ.coordinator_fee_ids.should_not be_empty
    occ.coordinator_fee_ids.should == oc.coordinator_fee_ids
    occ.preferred_product_selection_from_coordinator_inventory_only.should == oc.preferred_product_selection_from_coordinator_inventory_only

    # to_h gives us a unique hash for each exchange
    # check that the clone has no additional exchanges
    occ.exchanges.map(&:to_h).all? do |ex|
      oc.exchanges.map(&:to_h).include? ex
    end
    # check that the clone has original exchanges
    occ.exchanges.map(&:to_h).include? ex1.to_h
    occ.exchanges.map(&:to_h).include? ex2.to_h
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

  describe "finding open order cycles" do
    it "should give the soonest closing order cycle for a distributor" do
      distributor = create(:distributor_enterprise)
      oc = create(:simple_order_cycle, name: 'oc 1', distributors: [distributor], orders_open_at: 1.days.ago, orders_close_at: 11.days.from_now)
      oc2 = create(:simple_order_cycle, name: 'oc 2', distributors: [distributor], orders_open_at: 2.days.ago, orders_close_at: 12.days.from_now)
      OrderCycle.first_closing_for(distributor).should == oc
    end
  end

  describe "finding the earliest closing times for each distributor" do
    let(:time1) { 1.week.from_now }
    let(:time2) { 2.weeks.from_now }
    let(:time3) { 3.weeks.from_now }
    let(:e1) { create(:distributor_enterprise) }
    let(:e2) { create(:distributor_enterprise) }
    let!(:oc1) { create(:simple_order_cycle, orders_close_at: time1, distributors: [e1]) }
    let!(:oc2) { create(:simple_order_cycle, orders_close_at: time2, distributors: [e2]) }
    let!(:oc3) { create(:simple_order_cycle, orders_close_at: time3, distributors: [e2]) }

    it "returns the closing time, indexed by enterprise id" do
      OrderCycle.earliest_closing_times[e1.id].should == time1
    end

    it "returns the earliest closing time" do
      OrderCycle.earliest_closing_times[e2.id].should == time2
    end
  end

  describe "finding all line items sold by to a user by a given shop" do
    let(:shop) { create(:enterprise) }
    let(:user) { create(:user) }
    let(:oc) { create(:order_cycle) }
    let!(:order1) { create(:completed_order_with_totals, distributor: shop, user: user, order_cycle: oc)  }
    let!(:order2) { create(:completed_order_with_totals, distributor: create(:enterprise), user: user, order_cycle: oc)  }
    let!(:order3) { create(:completed_order_with_totals, distributor: shop, user: create(:user), order_cycle: oc)  }
    let!(:order4) { create(:completed_order_with_totals, distributor: shop, user: user, order_cycle: create(:order_cycle))  }
    let!(:order5) { create(:completed_order_with_totals, distributor: shop, user: user, order_cycle: oc)  }

    before do
      Spree::MailMethod.create!(
        environment: Rails.env,
        preferred_mails_from: 'spree@example.com'
      )
    end
    before { order5.cancel }

    it "only returns items from non-cancelled orders in the OC, placed by the user at the shop" do
      items = oc.items_bought_by_user(user, shop)
      expect(items).to eq order1.reload.line_items
    end
  end
end
