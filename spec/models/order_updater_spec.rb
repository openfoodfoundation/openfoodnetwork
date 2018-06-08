require 'spec_helper'

describe OrderUpdater do
  let(:order) { build(:order) }
  let(:order_updater) { described_class.new(Spree::OrderUpdater.new(order)) }

  context "#updating_payment_state" do
    it "is failed if no valid payments" do
      allow(order).to receive_message_chain(:payments, :valid, :empty?) { true }

      order_updater.update_payment_state
      expect(order.payment_state).to eq('failed')
    end

    context "payment total is greater than order total" do
      before do
        order.payment_total = 2
        order.total = 1
      end

      it "is credit_owed" do
        expect {
          order_updater.update_payment_state
        }.to change { order.payment_state }.to 'credit_owed'
      end
    end

    context "order total is greater than payment total" do
      before do
        order.payment_total = 1
        order.total = 2
      end

      it "is credit_owed" do
        expect {
          order_updater.update_payment_state
        }.to change { order.payment_state }.to 'balance_due'
      end
    end

    context "order total equals payment total" do
      before do
        order.payment_total = 30
        order.total = 30
      end

      it "is paid" do
        expect {
          order_updater.update_payment_state
        }.to change { order.payment_state }.to 'paid'
      end
    end

    context "order is canceled" do
      before { order.state = 'canceled' }

      context "and is still unpaid" do
        before do
          order.payment_total = 0
          order.total = 30
        end

        it "is void" do
          expect {
            order_updater.update_payment_state
          }.to change { order.payment_state }.to 'void'
        end
      end

      context "and is paid" do
        before do
          order.payment_total = 30
          order.total = 30
          order.stub_chain(:payments, :valid, :empty?).and_return(false)
          order.stub_chain(:payments, :completed, :empty?).and_return(false)
        end

        it "is credit_owed" do
          expect {
            order_updater.update_payment_state
          }.to change { order.payment_state }.to 'credit_owed'
        end
      end

      context "and payment is refunded" do
        before do
          order.payment_total = 0
          order.total = 30
          order.stub_chain(:payments, :valid, :empty?).and_return(false)
          order.stub_chain(:payments, :completed, :empty?).and_return(false)
        end

        it "is void" do
          expect {
            order_updater.update_payment_state
          }.to change { order.payment_state }.to 'void'
        end
      end
    end
  end

  context '#before_save_hook' do
    let(:distributor) { build(:distributor_enterprise) }
    let(:order) { build(:order, distributor: distributor) }
    let(:shipment) { build(:shipment) }
    let(:shipping_rate) do
      Spree::ShippingRate.new(
        shipping_method: shipping_method,
        selected: true
      )
    end

    before do
      shipment.shipping_rates << shipping_rate
      order.shipments << shipment
    end

    context 'when any of the shipping methods doesn\'t require a delivery address' do
      let(:shipping_method) { build(:base_shipping_method, require_ship_address: false) }

      let(:delivery_shipment) { build(:shipment) }
      let(:delivery_shipping_rate) do
        Spree::ShippingRate.new(
          shipping_method: build(:base_shipping_method, require_ship_address: true),
          selected: true
        )
      end

      before do
        delivery_shipment.shipping_rates << delivery_shipping_rate
        order.shipments << delivery_shipment
      end

      it "populates the shipping address" do
        order_updater.before_save_hook
        expect(order.ship_address.firstname).to eq(distributor.address.firstname)
      end
    end

    context 'when any of the shipping methods requires a delivery address' do
      let(:shipping_method) { build(:base_shipping_method, require_ship_address: true) }
      let(:address) { build(:address, firstname: 'will') }

      before { order.ship_address = address }

      it "does not populate the shipping address" do
        order_updater.before_save_hook
        expect(order.ship_address.firstname).to eq("will")
      end
    end
  end
end
