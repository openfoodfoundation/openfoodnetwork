require 'spec_helper'

module Spree
  describe Distributor do

    describe "associations" do
      it { should belong_to(:pickup_address) }
      it { should have_and_belong_to_many(:products) }
      it { should have_many(:orders) }
    end

    it "should default country to system country" do
      distributor = Distributor.new
      distributor.pickup_address.country.should == Country.find_by_id(Config[:default_country_id])
    end

    describe "validations" do
      it { should validate_presence_of(:name) }
    end
  end
end
