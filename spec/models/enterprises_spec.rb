require 'spec_helper'

describe Enterprise do

  describe "associations" do
    it { should have_many(:supplied_products) }
    it { should have_many(:distributed_orders) }
    it { should belong_to(:address) }
    it { should have_many(:product_distributions) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  it "should default address country to system country" do
    subject.address.country.should == Spree::Country.find_by_id(Spree::Config[:default_country_id])
  end

  describe "scopes" do
    describe "active_distributors" do
      it "finds active distributors by product distributions" do
        d = create(:distributor_enterprise)
        create(:product, :distributors => [d])
        Enterprise.active_distributors.should == [d]
      end

      it "doesn't show distributors of deleted products" do
        d = create(:distributor_enterprise)
        create(:product, :distributors => [d], :deleted_at => Time.now)
        Enterprise.active_distributors.should be_empty
      end

      it "doesn't show distributors of unavailable products" do
        d = create(:distributor_enterprise)
        create(:product, :distributors => [d], :available_on => 1.week.from_now)
        Enterprise.active_distributors.should be_empty
      end

      it "doesn't show distributors of out of stock products" do
        d = create(:distributor_enterprise)
        create(:product, :distributors => [d], :on_hand => 0)
        Enterprise.active_distributors.should be_empty
      end

      it "finds active distributors by order cycles" do
        s = create(:supplier_enterprise)
        d = create(:distributor_enterprise)
        p = create(:product)
        create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])
        Enterprise.active_distributors.should == [d]
      end

      it "doesn't show distributors from inactive order cycles" do
        s = create(:supplier_enterprise)
        d = create(:distributor_enterprise)
        p = create(:product)
        create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master], orders_open_at: 1.week.from_now, orders_close_at: 2.weeks.from_now)
        Enterprise.active_distributors.should be_empty
      end
    end


    it "returns distributors with products in stock" do
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      d3 = create(:distributor_enterprise)
      d4 = create(:distributor_enterprise)
      create(:product, :distributors => [d1, d2], :on_hand => 5)
      create(:product, :distributors => [d1], :on_hand => 5)
      create(:product, :distributors => [d3], :on_hand => 0)

      Enterprise.with_distributed_active_products_on_hand.sort.should == [d1, d2]
    end
  end

  describe "has_supplied_products_on_hand?" do
    before :each do
      @supplier = create(:supplier_enterprise)
    end

    it "returns false when no products" do
      @supplier.should_not have_supplied_products_on_hand
    end

    it "returns false when the product is out of stock" do
      create(:product, :supplier => @supplier, :on_hand => 0)
      @supplier.should_not have_supplied_products_on_hand
    end

    it "returns true when the product is in stock" do
      create(:product, :supplier => @supplier, :on_hand => 1)
      @supplier.should have_supplied_products_on_hand
    end
  end

  # TODO: Rename to distributed_variants?
  describe "finding variants distributed by the enterprise" do
    it "finds the master variant" do
      d = create(:distributor_enterprise)
      p = create(:product, distributors: [d])
      d.available_variants.should == [p.master]
    end

    it "finds other variants" do
      d = create(:distributor_enterprise)
      p = create(:product, distributors: [d])
      v = create(:variant, product: p)
      d.available_variants.sort.should == [p.master, v].sort
    end

    it "finds variants distributed by order cycle" do
      d = create(:distributor_enterprise)
      p = create(:product)
      oc = create(:simple_order_cycle, distributors: [d], variants: [p.master])
      d.available_variants.should == [p.master]
    end
  end
end
