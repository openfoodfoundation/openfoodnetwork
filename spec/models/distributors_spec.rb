require 'spec_helper'

module Spree
  describe Distributor do

    describe "associations" do
      it { should belong_to(:pickup_address) }
      it { should have_many(:product_distributions) }
      it { should have_many(:orders) }
    end

    describe "validations" do
      it { should validate_presence_of(:name) }
    end

    it "should default country to system country" do
      distributor = Distributor.new
      distributor.pickup_address.country.should == Country.find_by_id(Config[:default_country_id])
    end

    describe "scopes" do
      it "returns distributors with products in stock" do
        d1 = create(:distributor)
        d2 = create(:distributor)
        d3 = create(:distributor)
        d4 = create(:distributor)
        create(:product, :distributors => [d1, d2], :on_hand => 5)
        create(:product, :distributors => [d1], :on_hand => 5)
        create(:product, :distributors => [d3], :on_hand => 0)

        Distributor.with_active_products_on_hand.sort.should == [d1, d2]
      end
    end

  end
end
