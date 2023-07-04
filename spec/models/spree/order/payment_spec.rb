# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe Spree::Order do
    let(:order) { build(:order) }
    let(:updater) { OrderManagement::Order::Updater.new(order) }
    let(:bogus) { create(:bogus_payment_method, distributors: [create(:enterprise)]) }

    before do
      allow(order).to receive_message_chain(:line_items, :empty?).and_return(false)
      allow(order).to receive_messages total: 100
    end

    it 'processes all payments' do
      payment1 = create(:payment, amount: 50, payment_method: bogus)
      payment2 = create(:payment, amount: 50, payment_method: bogus)
      allow(order).to receive(:pending_payments).and_return([payment1, payment2])

      order.process_payments!
      updater.update_payment_state
      expect(order.payment_state).to eq 'paid'

      expect(payment1).to be_completed
      expect(payment2).to be_completed
    end

    it 'does not go over total for order' do
      payment1 = create(:payment, amount: 50, payment_method: bogus)
      payment2 = create(:payment, amount: 50, payment_method: bogus)
      payment3 = create(:payment, amount: 50, payment_method: bogus)
      allow(order).to receive(:pending_payments).and_return([payment1, payment2, payment3])

      order.process_payments!
      updater.update_payment_state
      expect(order.payment_state).to eq 'paid'

      expect(payment1).to be_completed
      expect(payment2).to be_completed
      expect(payment3).to be_checkout
    end

    it "does not use failed payments" do
      payment1 = create(:payment, amount: 50, payment_method: bogus)
      payment2 = create(:payment, amount: 50, state: 'failed', payment_method: bogus)
      allow(order).to receive(:pending_payments).and_return([payment1])

      expect(payment2).not_to receive(:process!)

      order.process_payments!
    end

    context "with a zero-priced order" do
      let!(:zero_order) {
        create(:order, state: "payment", line_items: [create(:line_item, price: 0)])
      }
      let!(:zero_payment) { create(:payment, order: zero_order, amount: 0, state: "checkout") }
      let(:updater) { OrderManagement::Order::Updater.new(zero_order) }

      it "processes payments successfully" do
        zero_order.process_payments!
        updater.update_payment_state

        expect(zero_order.payment_state).to eq "paid"
        expect(zero_payment.reload.state).to eq "completed"
        expect(zero_payment.captured_at).to_not be_nil
      end
    end
  end
end
