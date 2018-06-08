require 'spec_helper'

describe Spree::OrderUpdater do
  context "#updating_payment_state" do
    let(:order) { build(:order) }
    let(:order_updater) { described_class.new(order) }

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
end
