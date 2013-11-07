require 'spec_helper'

module Spree
  describe ShippingMethod do
    it "is valid when built from factory" do
      build(:shipping_method).should be_valid
    end

    it "can have distributors" do
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      sm = create(:shipping_method)

      sm.distributors.clear
      sm.distributors << d1
      sm.distributors << d2

      sm.reload.distributors.should == [d1, d2]
    end

    it "finds shipping methods for a particular distributor" do
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      sm1 = create(:shipping_method, distributors: [d1])
      sm2 = create(:shipping_method, distributors: [d2])

      ShippingMethod.for_distributor(d1).should == [sm1]
    end

    it "orders shipping methods by name" do
      sm1 = create(:shipping_method, name: 'ZZ')
      sm2 = create(:shipping_method, name: 'AA')
      sm3 = create(:shipping_method, name: 'BB')

      ShippingMethod.by_name.should == [sm2, sm3, sm1]
    end


    describe "availability" do
      let(:sm) { build(:shipping_method) }

      it "is available to orders that match its distributor" do
        o = build(:order, ship_address: build(:address), distributor: sm.distributors.first)
        sm.should be_available_to_order o
      end

      it "is not available to orders that do not match its distributor" do
        o = build(:order, ship_address: build(:address),
                  distributor: build(:distributor_enterprise))
        sm.should_not be_available_to_order o
      end
    end
  end
end
