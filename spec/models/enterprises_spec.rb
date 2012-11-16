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
