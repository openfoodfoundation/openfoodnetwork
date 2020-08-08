# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe Spree::Order do
    let(:order) { build(:order) }
    let(:updater) { Spree::OrderUpdater.new(order) }
    let(:bogus) { create(:bogus_payment_method, distributors: [create(:enterprise)]) }    

    before do
      # So that Payment#purchase! is called during processing
      Spree::Config[:auto_capture] = true

      order.stub_chain(:line_items, :empty?).and_return(false)
      order.stub total: 100
    end

    it 'processes all payments' do
      payment1 = create(:payment, amount: 50, payment_method: bogus)
      payment2 = create(:payment, amount: 50, payment_method: bogus)
      order.stub(:pending_payments).and_return([payment1, payment2])

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
      order.stub(:pending_payments).and_return([payment1, payment2, payment3])

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
      order.stub(:pending_payments).and_return([payment1])

      payment2.should_not_receive(:process!)

      order.process_payments!
    end
  end
end
