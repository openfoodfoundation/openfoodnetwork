require 'spec_helper'

describe OrderUpdater do
  let(:order) { build(:order) }
  let(:order_updater) { described_class.new(Spree::OrderUpdater.new(order)) }

  it "is failed if no valid payments" do
    allow(order).to receive_message_chain(:payments, :valid, :empty?).and_return(true)

    order_updater.update_payment_state
    expect(order.payment_state).to eq('failed')
  end

  context "payment total is greater than order total" do
    it "is credit_owed" do
      order.payment_total = 2
      order.total = 1

      expect {
        order_updater.update_payment_state
      }.to change { order.payment_state }.to 'credit_owed'
    end
  end

  context "order total is greater than payment total" do
    it "is credit_owed" do
      order.payment_total = 1
      order.total = 2

      expect {
        order_updater.update_payment_state
      }.to change { order.payment_state }.to 'balance_due'
    end
  end

  context "order total equals payment total" do
    it "is paid" do
      order.payment_total = 30
      order.total = 30

      expect {
        order_updater.update_payment_state
      }.to change { order.payment_state }.to 'paid'
    end
  end

  context "order is canceled" do
    before do
      order.state = 'canceled'
    end

    context "and is still unpaid" do
      it "is void" do
        order.payment_total = 0
        order.total = 30
        expect {
          order_updater.update_payment_state
        }.to change { order.payment_state }.to 'void'
      end
    end

    context "and is paid" do
      it "is credit_owed" do
        order.payment_total = 30
        order.total = 30
        allow(order).to receive_message_chain(:payments, :valid, :empty?).and_return(false)
        allow(order).to receive_message_chain(:payments, :completed, :empty?).and_return(false)
        expect {
          order_updater.update_payment_state
        }.to change { order.payment_state }.to 'credit_owed'
      end
    end

    context "and payment is refunded" do
      it "is void" do
        order.payment_total = 0
        order.total = 30
        allow(order).to receive_message_chain(:payments, :valid, :empty?).and_return(false)
        allow(order).to receive_message_chain(:payments, :completed, :empty?).and_return(false)
        expect {
          order_updater.update_payment_state
        }.to change { order.payment_state }.to 'void'
      end
    end
  end

  context 'when the set payment_state does not match the last payment_state' do
    before { order.payment_state = 'previous_to_paid' }

    context 'and the order is being updated' do
      before { allow(order).to receive(:persisted?) { true } }

      it 'creates a new state_change for the order' do
        expect { order_updater.update_payment_state }
          .to change { order.state_changes.size }.by(1)
      end
    end

    context 'and the order is being created' do
      before { allow(order).to receive(:persisted?) { false } }

      it 'creates a new state_change for the order' do
        expect { order_updater.update_payment_state }
          .not_to change { order.state_changes.size }
      end
    end
  end

  context 'when the set payment_state matches the last payment_state' do
    before { order.payment_state = 'paid' }

    it 'does not create any state_change' do
      expect { order_updater.update_payment_state }
        .not_to change { order.state_changes.size }
    end
  end

  context '#before_save_hook' do
    let(:distributor) { build(:distributor_enterprise) }
    let(:shipment) { create(:shipment_with, :shipping_method, shipping_method: shipping_method) }

    before do
      order.distributor = distributor
      order.shipments = [shipment]
    end

    context 'when shipping method is pickup' do
      let(:shipping_method) { create(:shipping_method_with, :pickup) }
      let(:address) { build(:address, firstname: 'joe') }
      before { distributor.address = address }

      it "populates the shipping address from distributor" do
        order_updater.before_save_hook
        expect(order.ship_address.address1).to eq(distributor.address.address1)
      end
    end

    context 'when shipping_method is delivery' do
      let(:shipping_method) { create(:shipping_method_with, :delivery) }
      let(:address) { build(:address, firstname: 'will') }
      before { order.ship_address = address }

      it "does not populate the shipping address from distributor" do
        order_updater.before_save_hook
        expect(order.ship_address.firstname).to eq("will")
      end
    end
  end
end
