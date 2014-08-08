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

    it "generates a clean name for known Payment Method types" do
      Spree::PaymentMethod::Check.clean_name.should == "Cash/EFT/etc. (payments for which automatic validation is not required)"
      Spree::Gateway::Migs.clean_name.should == "MasterCard Internet Gateway Service (MIGS)"
      Spree::Gateway::PayPalExpress.clean_name.should == "PayPal Express"

      # Testing else condition
      Spree::Gateway::BogusSimple.clean_name.should == "BogusSimple"
    end
  end
end
