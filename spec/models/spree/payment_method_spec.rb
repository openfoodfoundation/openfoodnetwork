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
      Spree::Gateway::Pin.clean_name.should == "Pin Payments"
      Spree::Gateway::PayPalExpress.clean_name.should == "PayPal Express"
      Spree::Gateway::StripeConnect.clean_name.should == "Stripe"

      # Testing else condition
      Spree::Gateway::BogusSimple.clean_name.should == "BogusSimple"
    end

    it "computes the amount of fees" do
      pickup = create(:payment_method)
      order = create(:order)
      expect(pickup.compute_amount(order)).to eq 0
      transaction = create(:payment_method, calculator: Calculator::FlatRate.new(preferred_amount: 10))
      expect(transaction.compute_amount(order)).to eq 10
      transaction = create(:payment_method, calculator: Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10))
      expect(transaction.compute_amount(order)).to eq 0
      product = create(:product)
      order.add_variant(product.master)
      expect(transaction.compute_amount(order)).to eq 2.0
    end

    describe "scope" do
      describe "filtering to specified distributors" do
        let!(:distributor_a) { create(:distributor_enterprise) }
        let!(:distributor_b) { create(:distributor_enterprise) }
        let!(:distributor_c) { create(:distributor_enterprise) }

        let!(:payment_method_a) { create(:payment_method, distributors: [distributor_a, distributor_b]) }
        let!(:payment_method_b) { create(:payment_method, distributors: [distributor_b]) }
        let!(:payment_method_c) { create(:payment_method, distributors: [distributor_c]) }

        it "includes only unique records under specified distributors" do
          result = described_class.for_distributors([distributor_a, distributor_b])
          expect(result.length).to eq(2)
          expect(result).to include(payment_method_a)
          expect(result).to include(payment_method_b)
        end
      end
    end
  end
end
