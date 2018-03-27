require 'spec_helper'

module Spree
  describe ShippingMethod do
    it "is valid when built from factory" do
      expect(build(:shipping_method)).to be_valid
    end

    it "can have distributors" do
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      sm = create(:shipping_method)

      sm.distributors.clear
      sm.distributors << d1
      sm.distributors << d2

      expect(sm.reload.distributors).to match_array [d1, d2]
    end

    it "finds shipping methods for a particular distributor" do
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      sm1 = create(:shipping_method, distributors: [d1])
      sm2 = create(:shipping_method, distributors: [d2])

      expect(ShippingMethod.for_distributor(d1)).to eq([sm1])
    end

    it "orders shipping methods by name" do
      sm1 = create(:shipping_method, name: 'ZZ')
      sm2 = create(:shipping_method, name: 'AA')
      sm3 = create(:shipping_method, name: 'BB')

      expect(ShippingMethod.by_name).to eq([sm2, sm3, sm1])
    end


    describe "availability" do
      let(:sm) { create(:shipping_method) }
      let(:currency) { 'AUD' }

      before do
        sm.calculator.preferred_currency = currency
      end

      it "is available to orders that match its distributor" do
        o = create(:order, ship_address: create(:address),
                  distributor: sm.distributors.first, currency: currency)
        expect(sm).to be_available_to_order o
      end

      it "is not available to orders that do not match its distributor" do
        o = create(:order, ship_address: create(:address),
                  distributor: create(:distributor_enterprise), currency: currency)
        expect(sm).not_to be_available_to_order o
      end

      it "is available to orders with no shipping address" do
        o = create(:order, ship_address: nil,
                  distributor: sm.distributors.first, currency: currency)
        expect(sm).to be_available_to_order o
      end
    end

    describe "finding services offered by all distributors" do
      let!(:d1) { create(:distributor_enterprise) }
      let!(:d2) { create(:distributor_enterprise) }
      let!(:d3) { create(:distributor_enterprise) }
      let!(:d4) { create(:distributor_enterprise) }
      let!(:d1_pickup) { create(:shipping_method, require_ship_address: false, distributors: [d1]) }
      let!(:d1_delivery) { create(:shipping_method, require_ship_address: true, distributors: [d1]) }
      let!(:d2_pickup) { create(:shipping_method, require_ship_address: false, distributors: [d2]) }
      let!(:d3_delivery) { create(:shipping_method, require_ship_address: true, distributors: [d3]) }

      it "reports when the services are available" do
        expect(ShippingMethod.services[d1.id]).to eq({pickup: true, delivery: true})
      end

      it "reports when only pickup is available" do
        expect(ShippingMethod.services[d2.id]).to eq({pickup: true, delivery: false})
      end

      it "reports when only delivery is available" do
        expect(ShippingMethod.services[d3.id]).to eq({pickup: false, delivery: true})
      end

      it "returns no entry when no service is available" do
        expect(ShippingMethod.services[d4.id]).to be_nil
      end
    end

    describe '#delivery?' do
      context 'when the shipping method requires an address' do
        let(:shipping_method) { build(:shipping_method, require_ship_address: true) }
        it { expect(shipping_method.delivery?).to be true }
      end

      context 'when the shipping method does not require address' do
        let(:shipping_method) { build(:shipping_method, require_ship_address: false) }
        it { expect(shipping_method.delivery?).to be false }
      end
    end
  end
end
