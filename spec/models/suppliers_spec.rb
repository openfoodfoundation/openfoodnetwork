require 'spec_helper'

module Spree
  describe Supplier do

    describe "associations" do
      it { should have_many(:products) }
      it { should belong_to(:address) }
    end

    it "should default country to system country" do
      supplier = Supplier.new
      supplier.address.country.should == Country.find_by_id(Config[:default_country_id])
    end

    describe "validations" do
      it { should validate_presence_of(:name) }
    end

  end
end
