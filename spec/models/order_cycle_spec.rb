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
    oc.coordinator_admin_fee = create(:enterprise_fee)
    oc.coordinator_sales_fee = create(:enterprise_fee)

    oc.save!
  end

  it "has exchanges" do
    oc = create(:simple_order_cycle)

    create(:exchange, order_cycle: oc)
    create(:exchange, order_cycle: oc)
    create(:exchange, order_cycle: oc)

    oc.exchanges.count.should == 3
  end

  it "finds active and inactive order cycles" do
    oc_active = create(:simple_order_cycle, orders_open_at: 1.week.ago, orders_close_at: 1.week.from_now)
    oc_not_yet_open = create(:simple_order_cycle, orders_open_at: 1.week.from_now, orders_close_at: 2.weeks.from_now)
    oc_already_closed = create(:simple_order_cycle, orders_open_at: 2.weeks.ago, orders_close_at: 1.week.ago)

    OrderCycle.active.should == [oc_active]
    OrderCycle.inactive.sort.should == [oc_not_yet_open, oc_already_closed].sort
  end

  describe "finding order cycles distributing a product" do
    it "returns order cycles distributing the product's master variant" do
      p = create(:product)
      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle, distributors: [d], variants: [p.master])
      OrderCycle.distributing_product(p).should == [oc]
    end

    it "returns order cycles distributing another variant" do
      p = create(:product)
      v = create(:variant, product: p)
      d = create(:distributor_enterprise)
      oc = create(:simple_order_cycle, distributors: [d], variants: [v])
      OrderCycle.distributing_product(p).should == [oc]
    end

    it "does not return order cycles supplying but not distributing a product" do
      p = create(:product)
      s = create(:supplier_enterprise)
      oc = create(:simple_order_cycle)
      ex = create(:exchange, order_cycle: oc, sender: s, receiver: oc.coordinator)
      ex.variants << p.master

      OrderCycle.distributing_product(p).should == []
    end
  end

  it "reports its suppliers" do
    oc = create(:simple_order_cycle)

    e1 = create(:exchange,
                order_cycle: oc, receiver: oc.coordinator, sender: create(:enterprise))
    e2 = create(:exchange,
                order_cycle: oc, receiver: oc.coordinator, sender: create(:enterprise))

    oc.suppliers.sort.should == [e1.sender, e2.sender].sort
  end

  it "reports its distributors" do
    oc = create(:simple_order_cycle)

    e1 = create(:exchange,
                order_cycle: oc, sender: oc.coordinator, receiver: create(:enterprise))
    e2 = create(:exchange,
                order_cycle: oc, sender: oc.coordinator, receiver: create(:enterprise))

    oc.distributors.sort.should == [e1.receiver, e2.receiver].sort
  end

  it "checks for existance of distributors" do
    oc = create(:simple_order_cycle)
    d1 = create(:distributor_enterprise)
    d2 = create(:distributor_enterprise)
    create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: d1)

    oc.should have_distributor(d1)
    oc.should_not have_distributor(d2)
  end

  describe "product exchanges" do
    before(:each) do
      @oc = create(:simple_order_cycle)

      e0 = create(:exchange,
                  order_cycle: @oc, sender: create(:enterprise), receiver: @oc.coordinator)
      e1 = create(:exchange,
                  order_cycle: @oc, sender: @oc.coordinator, receiver: create(:enterprise))
      e2 = create(:exchange,
                  order_cycle: @oc, sender: @oc.coordinator, receiver: create(:enterprise))

      @p0 = create(:product)
      @p1 = create(:product)
      @p2 = create(:product)
      @p2_v = create(:variant, product: @p2)

      e0.variants << @p0.master
      e1.variants << @p1.master
      e1.variants << @p2.master
      e1.variants << @p2_v
      e2.variants << @p1.master
    end

    it "reports on the variants exchanged in the order cycle" do
      @oc.variants.sort.should == [@p0.master, @p1.master, @p2.master, @p2_v].sort
    end

    it "reports on the variants distributed in the order cycle" do
      @oc.distributed_variants.sort.should == [@p1.master, @p2.master, @p2_v].sort
    end

    it "reports on the products exchanged in the order cycle" do
      @oc.products.sort.should == [@p0, @p1, @p2]
    end
  end
end
