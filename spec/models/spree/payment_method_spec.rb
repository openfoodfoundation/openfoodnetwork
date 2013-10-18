require 'spec_helper'

module Spree
  describe PaymentMethod do
    it "finds payment methods for a particular distributor" do
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      pm1 = create(:payment_method, distributors: [d1])
      pm2 = create(:payment_method, distributors: [d2])

      PaymentMethod.for_distributor(d1).should == [pm1]
    end
  end
end
