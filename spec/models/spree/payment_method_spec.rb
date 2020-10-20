require 'spec_helper'

class Spree::Gateway::Test < Spree::Gateway
end

module Spree
  describe PaymentMethod do
    describe "#available" do
      let(:enterprise) { create(:enterprise) }

      before do
        Spree::PaymentMethod.delete_all

        [nil, 'both', 'front_end', 'back_end'].each do |display_on|
          Spree::Gateway::Test.create(
            name: 'Display Both',
            display_on: display_on,
            active: true,
            environment: 'test',
            description: 'foofah',
            distributors: [enterprise]
          )
        end
        expect(Spree::PaymentMethod.all.size).to eq 4
      end

      it "should return all methods available to front-end/back-end when no parameter is passed" do
        expect(Spree::PaymentMethod.available.size).to eq 2
      end

      it "should return all methods available to front-end/back-end when display_on = :both" do
        expect(Spree::PaymentMethod.available(:both).size).to eq 2
      end

      it "should return all methods available to front-end when display_on = :front_end" do
        expect(Spree::PaymentMethod.available(:front_end).size).to eq 2
      end

      it "should return all methods available to back-end when display_on = :back_end" do
        expect(Spree::PaymentMethod.available(:back_end).size).to eq 2
      end
    end

    it "orders payment methods by name" do
      pm1 = create(:payment_method, name: 'ZZ')
      pm2 = create(:payment_method, name: 'AA')
      pm3 = create(:payment_method, name: 'BB')

      expect(PaymentMethod.by_name).to eq([pm2, pm3, pm1])
    end

    it "raises errors when required fields are missing" do
      pm = PaymentMethod.new
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
      order = create(:order)

      free_payment_method = create(:payment_method) # flat rate calculator with preferred_amount of 0
      expect(free_payment_method.compute_amount(order)).to eq 0

      flat_rate_payment_method = create(:payment_method, calculator: ::Calculator::FlatRate.new(preferred_amount: 10))
      expect(flat_rate_payment_method.compute_amount(order)).to eq 10

      flat_percent_payment_method = create(:payment_method, calculator: ::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10))
      expect(flat_percent_payment_method.compute_amount(order)).to eq 0

      product = create(:product)
      order.add_variant(product.master)
      expect(flat_percent_payment_method.compute_amount(order)).to eq 2.0
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
