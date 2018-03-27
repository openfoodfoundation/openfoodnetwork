require 'spec_helper'

module Spree
  describe PaymentMethod do
    it "orders payment methods by name" do
      pm1 = create(:payment_method, name: 'ZZ')
      pm2 = create(:payment_method, name: 'AA')
      pm3 = create(:payment_method, name: 'BB')

      expect(PaymentMethod.by_name).to eq([pm2, pm3, pm1])
    end

    it "raises errors when required fields are missing" do
      pm = PaymentMethod.new()
      pm.save
      expect(pm.errors.to_a).to eq(["Name can't be blank", "At least one hub must be selected"])
    end

    it "generates a clean name for known Payment Method types" do
      expect(Spree::PaymentMethod::Check.clean_name).to eq("Cash/EFT/etc. (payments for which automatic validation is not required)")
      expect(Spree::Gateway::Migs.clean_name).to eq("MasterCard Internet Gateway Service (MIGS)")
      expect(Spree::Gateway::Pin.clean_name).to eq("Pin Payments")
      expect(Spree::Gateway::PayPalExpress.clean_name).to eq("PayPal Express")
      expect(Spree::Gateway::StripeConnect.clean_name).to eq("Stripe")

      # Testing else condition
      expect(Spree::Gateway::BogusSimple.clean_name).to eq("BogusSimple")
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
  end
end
