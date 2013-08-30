require 'spec_helper'

module Spree
  describe ShippingMethod do
    it "should be valid when built from factory" do
      build(:shipping_method).should be_valid
    end

    it "should require a distributor" do
      build(:shipping_method, distributor: nil).should_not be_valid
    end
  end
end
