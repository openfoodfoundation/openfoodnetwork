# frozen_string_literal: true

require 'spec_helper'

describe OrderCycle do
  it "should be valid when built from factory" do
    expect(build(:simple_order_cycle)).to be_valid
  end

  it "should not be valid without a name" do
    oc = build(:simple_order_cycle)
    oc.name = ''
    expect(oc).not_to be_valid
  end

  it 'should not be valid when open date is after close date' do
    oc = build(:simple_order_cycle, orders_open_at: Time.zone.now, orders_close_at: 1.minute.ago)
    expect(oc).to_not be_valid
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

    expect(oc.exchanges.count).to eq(3)
  end

  it "finds order cycles in various stages of their lifecycle" do
    oc_active = create(:simple_order_cycle, orders_open_at: 1.week.ago,
                                            orders_close_at: 1.week.from_now)
    oc_not_yet_open = create(:simple_order_cycle, orders_open_at: 1.week.from_now,
                                                  orders_close_at: 2.weeks.from_now)
    oc_already_closed = create(:simple_order_cycle, orders_open_at: 2.weeks.ago,
                                                    orders_close_at: 1.week.ago)
    oc_undated = create(:simple_order_cycle, orders_open_at: nil, orders_close_at: nil)
    oc_undated_open = create(:simple_order_cycle, orders_open_at: 1.week.ago, orders_close_at: nil)
    oc_undated_close = create(:simple_order_cycle, orders_open_at: nil,
                                                   orders_close_at: 1.week.from_now)

    expect(OrderCycle.active).to eq([oc_active])
    expect(OrderCycle.inactive).to match_array [oc_not_yet_open, oc_already_closed]
    expect(OrderCycle.upcoming).to eq([oc_not_yet_open])
    expect(OrderCycle.closed).to eq([oc_already_closed])
    expect(OrderCycle.undated).to eq([oc_undated, oc_undated_open, oc_undated_close])
    expect(OrderCycle.not_closed).to eq([oc_active, oc_not_yet_open, oc_undated, oc_undated_open,
                                         oc_undated_close])
    expect(OrderCycle.dated).to eq([oc_active, oc_not_yet_open, oc_already_closed])
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

    expect(OrderCycle.visible_by(user)).to include(oc_coordinated, oc_sent, oc_received)
    expect(OrderCycle.visible_by(user)).not_to include(oc_not_accessible)
  end

  it "finds the most recently closed order cycles" do
    oc1 = create(:simple_order_cycle, orders_close_at: 2.hours.ago)
    oc2 = create(:simple_order_cycle, orders_close_at: 1.hour.ago)
    oc3 = create(:simple_order_cycle, orders_close_at: 1.hour.from_now)

    expect(OrderCycle.most_recently_closed).to eq([oc2, oc1])
  end

  it "finds the soonest opening order cycles" do
    oc1 = create(:simple_order_cycle, orders_open_at: 1.week.from_now)
    oc2 = create(:simple_order_cycle, orders_open_at: 2.hours.from_now)
    oc3 = create(:simple_order_cycle, orders_open_at: 1.hour.ago)

    expect(OrderCycle.soonest_opening).to eq([oc2, oc1])
  end

  it "finds the soonest closing order cycles" do
    oc1 = create(:simple_order_cycle, orders_close_at: 2.hours.ago)
    oc2 = create(:simple_order_cycle, orders_close_at: 2.hours.from_now)
    oc3 = create(:simple_order_cycle, orders_close_at: 1.hour.from_now)

    expect(OrderCycle.soonest_closing).to eq([oc3, oc2])
  end

  describe "finding order cycles with a particular distributor" do
    let(:c) { create(:supplier_enterprise) }
    let(:d) { create(:distributor_enterprise) }

    it "returns order cycles with that distributor" do
      oc = create(:simple_order_cycle, coordinator: c, distributors: [d])
      expect(OrderCycle.with_distributor(d)).to eq([oc])
    end

    it "does not return order cycles with that enterprise as supplier" do
      oc = create(:simple_order_cycle, coordinator: c, suppliers: [d])
      expect(OrderCycle.with_distributor(d)).to eq([])
    end

    it "does not return order cycles without that distributor" do
      oc = create(:simple_order_cycle, coordinator: c)
      expect(OrderCycle.with_distributor(d)).to eq([])
    end
  end

  it "reports its suppliers" do
    oc = create(:simple_order_cycle)

    e1 = create(:exchange, incoming: true,
                           order_cycle: oc, receiver: oc.coordinator, sender: create(:enterprise))
    e2 = create(:exchange, incoming: true,
                           order_cycle: oc, receiver: oc.coordinator, sender: create(:enterprise))

    expect(oc.suppliers).to match_array [e1.sender, e2.sender]
  end

  it "reports its distributors" do
    oc = create(:simple_order_cycle)

    e1 = create(:exchange, incoming: false,
                           order_cycle: oc, sender: oc.coordinator, receiver: create(:enterprise))
    e2 = create(:exchange, incoming: false,
                           order_cycle: oc, sender: oc.coordinator, receiver: create(:enterprise))

    expect(oc.distributors).to match_array [e1.receiver, e2.receiver]
  end

  it "checks for existance of distributors" do
    oc = create(:simple_order_cycle)
    d1 = create(:distributor_enterprise)
    d2 = create(:distributor_enterprise)
    create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d1, incoming: false)

    expect(oc).to have_distributor(d1)
    expect(oc).not_to have_distributor(d2)
  end

  it "checks for variants" do
    p1 = create(:simple_product)
    p2 = create(:simple_product)
    oc = create(:simple_order_cycle, suppliers: [p1.supplier], variants: [p1.variants.first])

    expect(oc).to have_variant(p1.variants.first)
    expect(oc).not_to have_variant(p2.variants.first)
  end

  describe "product exchanges" do
    let(:oc) { create(:simple_order_cycle) }
    let(:d1) { create(:enterprise) }
    let(:d2) { create(:enterprise) }
    let!(:e0) {
      create(:exchange, incoming: true,
                        order_cycle: oc, sender: create(:enterprise), receiver: oc.coordinator)
    }
    let!(:e1) {
      create(:exchange, incoming: false,
                        order_cycle: oc, sender: oc.coordinator, receiver: d1)
    }
    let!(:e2) {
      create(:exchange, incoming: false,
                        order_cycle: oc, sender: oc.coordinator, receiver: d2)
    }
    let!(:p0) { create(:simple_product) }
    let!(:p1) { create(:simple_product) }
    let!(:p1_v_deleted) { create(:variant, product: p1) }
    let!(:p1_v_visible) {
      create(:variant, product: p1,
                       inventory_items: [create(:inventory_item, enterprise: d2, visible: true)])
    }
    let!(:p1_v_hidden) {
      create(:variant, product: p1,
                       inventory_items: [create(:inventory_item, enterprise: d2, visible: false)])
    }
    let!(:p2) { create(:simple_product) }
    let!(:p2_v) { create(:variant, product: p2) }

    before(:each) do
      p1_v_deleted.deleted_at = Time.zone.now
      p1_v_deleted.save

      e0.variants << p0.variants.first
      e1.variants << p1.variants.first
      e1.variants << p2.variants.first
      e1.variants << p2_v
      e2.variants << p1.variants.first
      e2.variants << p1_v_deleted
      e2.variants << p1_v_visible
      e2.variants << p1_v_hidden
    end

    it "reports on the variants exchanged" do
      expect(oc.variants)
        .to match_array [p0.variants.first, p1.variants.first, p2.variants.first, p2_v,
                         p1_v_visible, p1_v_hidden]
    end

    it "returns the correct count of variants" do
      expect(oc.variants.count).to eq(6)
    end

    it "reports on the variants supplied" do
      expect(oc.supplied_variants).to match_array [p0.variants.first]
    end

    it "reports on the variants distributed" do
      expect(oc.distributed_variants)
        .to match_array [p1.variants.first, p2.variants.first, p2_v, p1_v_visible, p1_v_hidden]
    end

    it "reports on the products distributed by a particular distributor" do
      expect(oc.products_distributed_by(d2)).to eq([p1])
    end

    it "reports on the products exchanged" do
      expect(oc.products).to match_array [p0, p1, p2]
    end

    context "listing variant distributed by a particular distributor" do
      context "when default settings are in play" do
        it "returns an empty list when no distributor is given" do
          expect(oc.variants_distributed_by(nil)).to eq([])
        end

        it "returns all variants in the outgoing exchange for the distributor provided" do
          expect(oc.variants_distributed_by(d2)).to include p1.variants.first, p1_v_visible
          expect(oc.variants_distributed_by(d2)).not_to include p1_v_hidden, p1_v_deleted
          expect(oc.variants_distributed_by(d1)).to include p2_v
        end

        context "with soft-deleted variants" do
          it "does not consider soft-deleted variants to be currently distributed in the oc" do
            p2_v.delete

            expect(oc.variants_distributed_by(d1)).to_not include p2_v
          end
        end
      end

      context "when hub prefers product selection from inventory only" do
        before do
          allow(d1).to receive(:prefers_product_selection_from_inventory_only?) { true }
        end

        it "returns an empty list when no distributor is given" do
          expect(oc.variants_distributed_by(nil)).to eq([])
        end

        it "returns only variants in the exchange that are also in the distributor's inventory" do
          expect(oc.variants_distributed_by(d1)).not_to include p2_v
        end
      end
    end
  end

  describe "exchanges" do
    before(:each) do
      @oc = create(:simple_order_cycle)

      @d1 = create(:enterprise)
      @d2 = create(:enterprise, next_collection_at: '2-8pm Friday')

      @e0 = create(:exchange, order_cycle: @oc, sender: create(:enterprise),
                              receiver: @oc.coordinator, incoming: true)
      @e1 = create(:exchange, order_cycle: @oc, sender: @oc.coordinator, receiver: @d1,
                              incoming: false, pickup_time: '5pm Tuesday',
                              pickup_instructions: "Come get it!")
      @e2 = create(:exchange, order_cycle: @oc, sender: @oc.coordinator, receiver: @d2,
                              incoming: false, pickup_time: nil)
    end

    it "finds the exchange for a distributor" do
      expect(@oc.exchange_for_distributor(@d1)).to eq(@e1)
      expect(@oc.exchange_for_distributor(@d2)).to eq(@e2)
    end

    describe "finding pickup time for a distributor" do
      it "looks up the pickup time on the exchange when present" do
        expect(@oc.pickup_time_for(@d1)).to eq('5pm Tuesday')
      end

      it "returns the distributor's default collection time otherwise" do
        expect(@oc.pickup_time_for(@d2)).to eq('2-8pm Friday')
      end
    end

    describe "finding pickup instructions for a distributor" do
      it "returns the pickup instructions" do
        expect(@oc.pickup_instructions_for(@d1)).to eq("Come get it!")
      end
    end
  end

  describe "checking status" do
    let(:oc) { build_stubbed(:simple_order_cycle) }

    it "reports status when an order cycle is upcoming" do
      Timecop.freeze(oc.orders_open_at - 1.second) do
        expect(oc).not_to be_undated
        expect(oc).to     be_dated
        expect(oc).to     be_upcoming
        expect(oc).not_to be_open
        expect(oc).not_to be_closed
      end
    end

    it "reports status when an order cycle is open" do
      expect(oc).not_to be_undated
      expect(oc).to     be_dated
      expect(oc).not_to be_upcoming
      expect(oc).to     be_open
      expect(oc).not_to be_closed
    end

    it "reports status when an order cycle has closed" do
      Timecop.freeze(oc.orders_close_at + 1.second) do
        expect(oc).not_to be_undated
        expect(oc).to     be_dated
        expect(oc).not_to be_upcoming
        expect(oc).not_to be_open
        expect(oc).to     be_closed
      end
    end

    it "reports status when an order cycle is undated" do
      oc.orders_open_at = nil
      oc.orders_close_at = nil

      expect(oc).to     be_undated
      expect(oc).not_to be_dated
      expect(oc).not_to be_upcoming
      expect(oc).not_to be_open
      expect(oc).not_to be_closed
    end

    it "reports status when an order cycle is partially dated - opening time only" do
      oc.orders_close_at = nil

      expect(oc).to     be_undated
      expect(oc).not_to be_dated
      expect(oc).not_to be_upcoming
      expect(oc).not_to be_open
      expect(oc).not_to be_closed
    end

    it "reports status when an order cycle is partially dated - closing time only" do
      oc.orders_open_at = nil

      expect(oc).to     be_undated
      expect(oc).not_to be_dated
      expect(oc).not_to be_upcoming
      expect(oc).not_to be_open
      expect(oc).not_to be_closed
    end
  end

  describe "finding recently closed order cycles" do
    it "should give the most recently closed order cycle for a distributor" do
      distributor = create(:distributor_enterprise)
      oc = create(:simple_order_cycle, name: 'oc 1', distributors: [distributor],
                                       orders_open_at: 10.days.ago, orders_close_at: 9.days.ago)
      expect(OrderCycle.most_recently_closed_for(distributor)).to eq(oc)
    end

    it "should return nil when there have been none" do
      distributor = create(:distributor_enterprise)
      expect(OrderCycle.most_recently_closed_for(distributor)).to eq(nil)
    end
  end

  describe "finding order cycles opening in the future" do
    it "should give the soonest opening order cycle for a distributor" do
      distributor = create(:distributor_enterprise)
      oc = create(:simple_order_cycle, name: 'oc 1', distributors: [distributor],
                                       orders_open_at: 10.days.from_now,
                                       orders_close_at: 11.days.from_now)
      expect(OrderCycle.first_opening_for(distributor)).to eq(oc)
    end

    it "should return no order cycle when none are impending" do
      distributor = create(:distributor_enterprise)
      expect(OrderCycle.first_opening_for(distributor)).to eq(nil)
    end
  end

  describe "finding open order cycles" do
    it "should give the soonest closing order cycle for a distributor" do
      distributor = create(:distributor_enterprise)
      oc = create(:simple_order_cycle, name: 'oc 1', distributors: [distributor],
                                       orders_open_at: 1.day.ago,
                                       orders_close_at: 11.days.from_now)
      oc2 = create(:simple_order_cycle, name: 'oc 2', distributors: [distributor],
                                        orders_open_at: 2.days.ago,
                                        orders_close_at: 12.days.from_now)
      expect(OrderCycle.first_closing_for(distributor)).to eq(oc)
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
      expect(OrderCycle.earliest_closing_times[e1.id].round).to eq(time1.round)
    end

    it "returns the earliest closing time" do
      expect(OrderCycle.earliest_closing_times[e2.id].round).to eq(time2.round)
    end
  end

  describe "finding all line items sold by to a user by a given shop" do
    let(:shop) { create(:enterprise) }
    let(:user) { create(:user) }
    let(:oc) { create(:order_cycle) }
    let!(:order) {
      create(:completed_order_with_totals, distributor: shop, user: user, order_cycle: oc)
    }
    let!(:order_from_other_hub) {
      create(:completed_order_with_totals, distributor: create(:enterprise), user: user,
                                           order_cycle: oc)
    }
    let!(:order_from_other_user) {
      create(:completed_order_with_totals, distributor: shop, user: create(:user), order_cycle: oc)
    }
    let!(:order_from_other_oc) {
      create(:completed_order_with_totals, distributor: shop, user: user,
                                           order_cycle: create(:order_cycle))
    }
    let!(:order_cancelled) {
      create(:completed_order_with_totals, distributor: shop, user: user, order_cycle: oc)
    }

    before { order_cancelled.cancel }

    it "only returns items from non-cancelled orders in the OC, placed by the user at the shop" do
      items = oc.items_bought_by_user(user, shop)
      expect(items).to match_array order.reload.line_items
    end

    it "returns items with scoped variants" do
      overridden_variant = order.line_items.first.variant
      create(:variant_override, hub: shop, variant: overridden_variant, count_on_hand: 1000)

      items = oc.items_bought_by_user(user, shop)

      expect(items).to match_array order.reload.line_items
      item_with_overridden_variant = items.find { |item| item.variant_id == overridden_variant.id }
      expect(item_with_overridden_variant.variant.on_hand).to eq(1000)
    end
  end

  describe "version tracking", versioning: true do
    let!(:oc) { create(:order_cycle, name: "Original") }

    it "remembers old versions" do
      expect {
        oc.update!(name: "New name")
      }.to change {
        oc.versions.count
      }.by(1)

      expect(oc.versions.last.reify.name).to eq "Original"
    end

    # Needs additional gem:
    # https://github.com/westonganger/paper_trail-association_tracking
    xit "records versions when adding schedules" do
      pending "seems broken with current version"

      expect {
        # Creating a schedule associates it automatically:
        create(:schedule)
        expect(oc.schedules.count).to eq 1
      }.to change {
        oc.versions.count
      }.by(1)
    end

    it "records associated schedules" do
      schedule = create(:schedule)
      expect(oc.reload.schedules).to eq [schedule]
      oc.update!(name: "New name")

      expect(oc.versions.last.custom_data).to eq "[#{schedule.id}]"
    end

    it "remembers schedules of the previous version" do
      schedule = create(:schedule)
      expect(oc.reload.schedules).to eq [schedule]
      oc.update!(name: "New name", schedules: [])

      pending "gathering schedule ids before save"
      expect(oc.versions.last.custom_data).to eq "[#{schedule.id}]"
    end
  end

  describe "syncing subscriptions" do
    let!(:oc) {
      create(:simple_order_cycle, orders_open_at: 1.week.ago, orders_close_at: 1.day.ago)
    }
    let(:schedule) { create(:schedule, order_cycles: [oc]) }
    let!(:subscription) { create(:subscription, schedule: schedule, with_items: true) }

    it "syncs subscriptions when transitioning from closed to open" do
      expect(OrderManagement::Subscriptions::ProxyOrderSyncer).to receive(:new).and_call_original

      expect{
        oc.update(orders_close_at: 1.week.from_now)
      }.to change{ ProxyOrder.count }
    end

    it "syncs subscriptions when transitioning from closed to upcoming" do
      expect(OrderManagement::Subscriptions::ProxyOrderSyncer).to receive(:new).and_call_original

      expect {
        oc.update(orders_open_at: 1.day.from_now, orders_close_at: 1.week.from_now)
      }.to change{ ProxyOrder.count }
    end

    context "when the current dates are nil" do
      before { oc.update(orders_open_at: nil, orders_close_at: nil) }

      it "syncs subscriptions when transitioning from closed to open" do
        expect(OrderManagement::Subscriptions::ProxyOrderSyncer).to receive(:new).and_call_original

        expect{
          oc.update(orders_open_at: 1.day.ago, orders_close_at: 1.week.from_now)
        }.to change{ ProxyOrder.count }
      end
    end
  end

  describe "opened_at " do
    let!(:oc) {
      create(:simple_order_cycle, orders_open_at: 2.days.ago,
                                  orders_close_at: 1.day.ago, opened_at: 1.week.ago)
    }

    it "reset opened_at if open date change in future" do
      expect{ oc.update!(orders_open_at: 1.week.from_now, orders_close_at: 2.weeks.from_now) }
        .to change { oc.opened_at }.to be_nil
    end

    it "it does not reset opened_at if open date is changed to be earlier" do
      expect{ oc.update!(orders_open_at: 3.days.ago) }
        .to_not change { oc.opened_at }
    end

    it "it does not reset opened_at if open date does not change" do
      expect{ oc.update!(orders_close_at: 1.day.from_now) }
        .to_not change { oc.opened_at }
    end
  end

  describe "processed_at " do
    let!(:oc) {
      create(:simple_order_cycle, orders_open_at: 1.week.ago,
                                  orders_close_at: 1.day.ago, processed_at: 1.hour.ago)
    }

    it "reset processed_at if close date change in future" do
      expect(oc.processed_at).to_not be_nil
      oc.update!(orders_close_at: 1.week.from_now)
      expect(oc.processed_at).to be_nil
    end

    it "it does not reset processed_at if close date is changed to be earlier" do
      expect(oc.processed_at).to_not be_nil
      oc.update!(orders_close_at: 2.days.ago)
      expect(oc.processed_at).to_not be_nil
    end

    it "it does not reset processed_at if close date does not change" do
      expect(oc.processed_at).to_not be_nil
      oc.update!(orders_open_at: 2.weeks.ago)
      expect(oc.processed_at).to_not be_nil
    end
  end

  describe "#attachable_distributor_payment_methods" do
    it "includes distributor payment methods from the distributors on the order cycle" do
      payment_method = create(:payment_method)
      oc = create(:simple_order_cycle, distributors: [payment_method.distributors.first])
      distributor_payment_method = payment_method.distributor_payment_methods.first

      expect(oc.attachable_distributor_payment_methods).to eq([distributor_payment_method])
    end

    it "does not include backoffice only distributor payment methods" do
      payment_method = create(:payment_method, display_on: "back_end")
      enterprise = create(:enterprise, payment_methods: [payment_method])
      oc = create(:simple_order_cycle, distributors: [enterprise])

      expect(oc.attachable_distributor_payment_methods).to be_empty
    end

    it "does not include inactive distributor payment methods" do
      payment_method = create(:payment_method, active: false)
      enterprise = create(:enterprise, payment_methods: [payment_method])
      oc = create(:simple_order_cycle, distributors: [enterprise])

      expect(oc.attachable_distributor_payment_methods).to be_empty
    end
  end

  describe "#attachable_distributor_shipping_methods" do
    it "includes distributor shipping methods from the distributors on the order cycle" do
      shipping_method = create(:shipping_method)
      oc = create(:simple_order_cycle, distributors: [shipping_method.distributors.first])
      distributor_shipping_method = shipping_method.distributor_shipping_methods.first

      expect(oc.attachable_distributor_shipping_methods).to eq([distributor_shipping_method])
    end

    it "does not include backoffice only distributor shipping methods" do
      shipping_method = create(:shipping_method, display_on: "back_end")
      enterprise = create(:enterprise, shipping_methods: [shipping_method])
      oc = create(:simple_order_cycle, distributors: [enterprise])

      expect(oc.attachable_distributor_shipping_methods).to be_empty
    end
  end

  describe "#distributor_payment_methods" do
    let(:distributor) { create(:distributor_enterprise) }

    it "returns all attachable distributor payment methods if the order cycle is simple" do
      oc = create(:sells_own_order_cycle, distributors: [distributor])

      distributor_payment_method = create(
        :payment_method,
        distributors: [distributor]
      ).distributor_payment_methods.first

      expect(oc.distributor_payment_methods).to eq [distributor_payment_method]
    end

    context "distributor order cycle i.e. non-simple" do
      let(:oc) { create(:distributor_order_cycle, distributors: [distributor]) }

      it "returns all attachable distributor payment methods if no distributor payment methods
          have been selected specifically" do
        distributor_payment_method = create(
          :payment_method,
          distributors: [distributor]
        ).distributor_payment_methods.first

        expect(oc.selected_distributor_payment_methods).to be_empty
        expect(oc.distributor_payment_methods).to eq [distributor_payment_method]
      end

      it "returns selected distributor payment methods if they have been specified" do
        distributor_payment_method_i = create(
          :payment_method,
          distributors: [distributor]
        ).distributor_payment_methods.first
        distributor_payment_method_ii = create(
          :payment_method,
          distributors: [distributor]
        ).distributor_payment_methods.first

        oc.selected_distributor_payment_methods << distributor_payment_method_ii

        expect(oc.distributor_payment_methods).to eq [distributor_payment_method_ii]
      end

      context "with multiple distributors" do
        let(:other_distributor) { create(:distributor_enterprise) }
        let(:oc) {
          create(:distributor_order_cycle, distributors: [distributor, other_distributor])
        }

        it "returns all attachable distributor payment methods for a distributor if no distributor
            payment methods have been selected specifically for that distributor, even if
            distributor payment methods have been selected specifically for a different distributor
            on the order cycle" do
          distributor_payment_method = create(
            :payment_method,
            distributors: [distributor]
          ).distributor_payment_methods.first
          other_distributor_payment_method_i = create(
            :payment_method,
            distributors: [other_distributor]
          ).distributor_payment_methods.first
          other_distributor_payment_method_ii = create(
            :payment_method,
            distributors: [other_distributor]
          ).distributor_payment_methods.first
          oc.selected_distributor_payment_methods << other_distributor_payment_method_i

          expect(oc.distributor_payment_methods).to eq [
            distributor_payment_method,
            other_distributor_payment_method_i
          ]
        end
      end
    end
  end

  describe "#distributor_shipping_methods" do
    let(:distributor) { create(:distributor_enterprise) }

    it "returns all attachable distributor shipping methods if the order cycle is simple" do
      oc = create(:sells_own_order_cycle, distributors: [distributor])

      distributor_shipping_method = create(
        :shipping_method,
        distributors: [distributor]
      ).distributor_shipping_methods.first

      expect(oc.distributor_shipping_methods).to eq [distributor_shipping_method]
    end

    context "distributor order cycle i.e. non-simple" do
      let(:oc) { create(:distributor_order_cycle, distributors: [distributor]) }

      it "returns all attachable distributor shipping methods if no distributor shipping methods
          have been selected specifically" do
        distributor_shipping_method = create(
          :shipping_method,
          distributors: [distributor]
        ).distributor_shipping_methods.first

        expect(oc.selected_distributor_shipping_methods).to be_empty
        expect(oc.distributor_shipping_methods).to eq [distributor_shipping_method]
      end

      it "returns selected distributor shipping methods if they have been specified" do
        distributor_shipping_method_i = create(
          :shipping_method,
          distributors: [distributor]
        ).distributor_shipping_methods.first
        distributor_shipping_method_ii = create(
          :shipping_method,
          distributors: [distributor]
        ).distributor_shipping_methods.first

        oc.selected_distributor_shipping_methods << distributor_shipping_method_ii

        expect(oc.distributor_shipping_methods).to eq [distributor_shipping_method_ii]
      end

      context "with multiple distributors" do
        let(:other_distributor) { create(:distributor_enterprise) }
        let(:oc) {
          create(:distributor_order_cycle, distributors: [distributor, other_distributor])
        }

        it "returns all attachable distributor shipping methods for a distributor if no distributor
            shipping methods have been selected specifically for that distributor, even if
            distributor shipping methods have been selected specifically for a different distributor
            on the order cycle" do
          distributor_shipping_method = create(
            :shipping_method,
            distributors: [distributor]
          ).distributor_shipping_methods.first
          other_distributor_shipping_method_i = create(
            :shipping_method,
            distributors: [other_distributor]
          ).distributor_shipping_methods.first
          other_distributor_shipping_method_ii = create(
            :shipping_method,
            distributors: [other_distributor]
          ).distributor_shipping_methods.first
          oc.selected_distributor_shipping_methods << other_distributor_shipping_method_i

          expect(oc.distributor_shipping_methods).to eq [
            distributor_shipping_method,
            other_distributor_shipping_method_i
          ]
        end
      end
    end
  end

  describe "#simple?" do
    it "returns true if the coordinator sells their own products i.e. shops" do
      order_cycle = build(:simple_order_cycle, coordinator: build(:enterprise, sells: "own"))

      expect(order_cycle).to be_simple
    end

    it "returns false if the coordinator can sell other people's products i.e. hubs" do
      order_cycle = build(:simple_order_cycle, coordinator: build(:enterprise, sells: "any"))

      expect(order_cycle).not_to be_simple
    end
  end
end
