# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe ShippingMethod do
    it "is valid when built from factory" do
      expect(
        build(
          :shipping_method,
          shipping_categories: [Spree::ShippingCategory.new(name: 'Test')]
        )
      ).to be_valid
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

    describe "scope" do
      describe "filtering to specified distributors" do
        let!(:distributor_a) { create(:distributor_enterprise) }
        let!(:distributor_b) { create(:distributor_enterprise) }
        let!(:distributor_c) { create(:distributor_enterprise) }

        let!(:shipping_method_a) {
          create(:shipping_method, distributors: [distributor_a, distributor_b])
        }
        let!(:shipping_method_b) { create(:shipping_method, distributors: [distributor_b]) }
        let!(:shipping_method_c) { create(:shipping_method, distributors: [distributor_c]) }

        it "includes only unique records under specified distributors" do
          result = described_class.for_distributors([distributor_a, distributor_b])
          expect(result.length).to eq(2)
          expect(result).to include(shipping_method_a)
          expect(result).to include(shipping_method_b)
        end
      end

      it "finds shipping methods for a particular distributor" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        sm1 = create(:shipping_method, distributors: [d1])
        sm2 = create(:shipping_method, distributors: [d2])

        expect(ShippingMethod.for_distributor(d1)).to eq([sm1])
      end
    end

    it "orders shipping methods by name" do
      sm1 = create(:shipping_method, name: 'ZZ')
      sm2 = create(:shipping_method, name: 'AA')
      sm3 = create(:shipping_method, name: 'BB')

      expect(ShippingMethod.by_name).to eq([sm2, sm3, sm1])
    end

    describe "finding services offered by all distributors" do
      let!(:d1) { create(:distributor_enterprise) }
      let!(:d2) { create(:distributor_enterprise) }
      let!(:d3) { create(:distributor_enterprise) }
      let!(:d4) { create(:distributor_enterprise) }
      let!(:d1_pickup) { create(:shipping_method, require_ship_address: false, distributors: [d1]) }
      let!(:d1_delivery) {
        create(:shipping_method, require_ship_address: true, distributors: [d1])
      }
      let!(:d2_pickup) { create(:shipping_method, require_ship_address: false, distributors: [d2]) }
      let!(:d3_delivery) {
        create(:shipping_method, require_ship_address: true, distributors: [d3])
      }

      it "reports when the services are available" do
        expect(ShippingMethod.services[d1.id]).to eq(pickup: true, delivery: true)
      end

      it "reports when only pickup is available" do
        expect(ShippingMethod.services[d2.id]).to eq(pickup: true, delivery: false)
      end

      it "reports when only delivery is available" do
        expect(ShippingMethod.services[d3.id]).to eq(pickup: false, delivery: true)
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

    describe "#delivers_to?" do
      let(:shipping_method) { build_stubbed(:shipping_method) }

      it "does not deliver to a nil address" do
        expect(shipping_method.delivers_to?(nil)).to be false
      end

      it "includes an address that is not included in the zones of the shipping method" do
        address = create(:address)
        zone_mock = instance_double(Spree::Zone)
        allow(zone_mock).to receive(:contains?).with(address).and_return(false)
        allow(shipping_method).to receive(:zones) { [zone_mock] }

        expect(shipping_method.delivers_to?(address)).to be true
      end
    end

    describe "touches" do
      let!(:distributor) { create(:distributor_enterprise) }
      let!(:shipping_method) { create(:shipping_method) }
      let(:add_distributor) { shipping_method.distributors << distributor }

      it "is touched when applied to a distributor" do
        expect{ add_distributor }.to change { shipping_method.reload.updated_at }
      end
    end

    context "validations" do
      it "validates presence of name" do
        shipping_method = build_stubbed(
          :shipping_method,
          name: ''
        )
        expect(shipping_method).not_to be_valid
        expect(shipping_method.errors[:name].first).to eq "can't be blank"
      end

      describe "#display_on" do
        it "is valid when it's set to nil, an empty string or 'back_end'" do
          shipping_method = build_stubbed(
            :shipping_method,
            shipping_categories: [Spree::ShippingCategory.new(name: 'Test')]
          )
          [nil, "", "back_end"].each do |display_on_option|
            shipping_method.display_on = display_on_option
            expect(shipping_method).to be_valid
          end
        end

        it "is not valid when it's set to an unknown value" do
          shipping_method = build_stubbed(:shipping_method, display_on: "front_end")
          expect(shipping_method).not_to be_valid
          expect(shipping_method.errors[:display_on]).to eq ["is not included in the list"]
        end
      end

      context "shipping category" do
        it "validates presence of at least one" do
          shipping_method = build_stubbed(
            :shipping_method,
            shipping_categories: []
          )
          expect(shipping_method).not_to be_valid
          expect(shipping_method.errors[:base].first)
            .to eq "You need to select at least one shipping category"
        end

        context "one associated" do
          let(:shipping_method) do
            build_stubbed(
              :shipping_method,
              shipping_categories: [Spree::ShippingCategory.new(name: 'Test')]
            )
          end
          it { expect(shipping_method).to be_valid }
        end
      end
    end

    # Regression test for Spree #4320
    context "soft deletion" do
      let(:shipping_method) { create(:shipping_method) }

      it "soft-deletes when destroy is called" do
        shipping_method.destroy
        expect(shipping_method.deleted_at).to_not be_blank
      end
    end

    context 'factory' do
      let(:shipping_method){ create :shipping_method }

      it "should set calculable correctly" do
        expect(shipping_method.calculator.calculable).to eq(shipping_method)
      end
    end

    # Regression test for Spree #4492
    context "#shipments" do
      let!(:shipping_method) { create(:shipping_method) }
      let!(:shipment) do
        shipment = create(:shipment)
        shipment.shipping_rates.create!(shipping_method: shipping_method)
        shipment
      end

      it "can gather all the related shipments" do
        expect(shipping_method.shipments).to include(shipment)
      end
    end
  end
end
