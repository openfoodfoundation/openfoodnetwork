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
    it "returns distributors with available products in stock" do
      d1 = create(:distributor_enterprise) # two products on hand
      d2 = create(:distributor_enterprise) # one product on hand
      d3 = create(:distributor_enterprise) # product on hand but not yet available
      d4 = create(:distributor_enterprise) # no products on hand
      d5 = create(:distributor_enterprise) # deleted product
      d6 = create(:distributor_enterprise) # no products
      create(:product, :distributors => [d1, d2], :on_hand => 5)
      create(:product, :distributors => [d1], :on_hand => 5)
      create(:product, :distributors => [d3], :on_hand => 5, :available_on => 1.week.from_now)
      create(:product, :distributors => [d4], :on_hand => 0)
      create(:product, :distributors => [d5]).delete

      Enterprise.with_distributed_active_products_on_hand.sort.should == [d1, d2]
      Enterprise.with_distributed_active_products_on_hand.distinct_count.should == 2
    end
    
    it "returns suppliers with available products in stock" do
      d1 = create(:supplier_enterprise) # two products on hand
      d2 = create(:supplier_enterprise) # one product on hand
      d3 = create(:supplier_enterprise) # product on hand but not yet available
      d4 = create(:supplier_enterprise) # no products on hand
      d5 = create(:supplier_enterprise) # deleted product
      d6 = create(:supplier_enterprise) # no products
      create(:product, :supplier => d1, :on_hand => 5)
      create(:product, :supplier => d1, :on_hand => 5)
      create(:product, :supplier => d2, :on_hand => 5)
      create(:product, :supplier => d3, :on_hand => 5, :available_on => 1.week.from_now) 
      create(:product, :supplier => d4, :on_hand => 0) 
      create(:product, :supplier => d5).delete 

      Enterprise.with_supplied_active_products_on_hand.sort.should == [d1, d2]
      Enterprise.with_supplied_active_products_on_hand.distinct_count.should == 2
    end
  end

  context "has_supplied_products_on_hand?" do
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
end
