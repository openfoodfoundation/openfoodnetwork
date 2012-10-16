require 'spec_helper'

module Spree
  describe Supplier do

    describe "associations" do
      it { should have_many(:products) }
      it { should belong_to(:address) }
    end

    describe "validations" do
      it { should validate_presence_of(:name) }
    end

    it "should default country to system country" do
      subject.address.country.should == Country.find_by_id(Config[:default_country_id])
    end

    context "has_products_on_hand?" do
      before :each do
        @supplier = create(:supplier)
      end

      it "returns false when no products" do
        @supplier.should_not have_products_on_hand
      end

      it "returns false when the product is out of stock" do
        create(:product, :supplier => @supplier, :on_hand => 0)
        @supplier.should_not have_products_on_hand
      end

      it "returns true when the product is in stock" do
        create(:product, :supplier => @supplier, :on_hand => 1)
        @supplier.should have_products_on_hand
      end
    end
  end
end
