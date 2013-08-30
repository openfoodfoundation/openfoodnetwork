require 'spec_helper'

module Spree
  describe ShippingMethod do
    it "is valid when built from factory" do
      build(:shipping_method).should be_valid
    end

    it "requires a distributor" do
      build(:shipping_method, distributor: nil).should_not be_valid
    end

    describe "availability" do
      let(:sm) { build(:shipping_method) }

      it "is available to orders that match its distributor" do
        o = build(:order, ship_address: build(:address), distributor: sm.distributor)
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
