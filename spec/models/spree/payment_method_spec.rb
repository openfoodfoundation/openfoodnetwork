require 'spec_helper'

module Spree
  describe PaymentMethod do
    it "orders payment methods by name" do
      pm1 = create(:payment_method, name: 'ZZ')
      pm2 = create(:payment_method, name: 'AA')
      pm3 = create(:payment_method, name: 'BB')

      PaymentMethod.by_name.should == [pm2, pm3, pm1]
    end

    it "raises errors when required fields are missing" do
      pm = PaymentMethod.new()
      pm.save
      pm.errors.to_a.should == ["Name can't be blank", "At least one hub must be selected"]
    end
  end
end
