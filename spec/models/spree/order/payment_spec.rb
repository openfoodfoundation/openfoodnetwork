# frozen_string_literal: true

module Spree
  RSpec.describe Spree::Order do
    before { Stripe.api_key = "sk_test_12345" }
    let(:order) { build(:order) }
    let(:updater) { OrderManagement::Order::Updater.new(order) }
    let(:payment_method) {
      create(:stripe_sca_payment_method, distributor_ids: [create(:distributor_enterprise).id],
                                         preferred_enterprise_id: create(:enterprise).id)
    }
    let(:source) {
      create(:credit_card)
    }
    let(:payment1) {
      create(:payment, order:, amount: 50, payment_method:, source:, response_code: "12345")
    }
    let(:payment2) {
      create(:payment, order:, amount: 50, payment_method:, source:, response_code: "12345")
    }
    let(:payment3) {
      create(:payment, order:, amount: 50, payment_method:, source:, response_code: "12345")
    }
    let(:failed_payment) {
      create(:payment, amount: 50, state: 'failed', payment_method:, source:,
                       response_code: "12345")
    }
    let(:payment_authorised) {
      payment_intent(50, "requires_capture")
    }
    let(:capture_successful) {
      payment_intent(50, "succeeded")
    }

    before do
      # mock the call with "ofn.payment_transition" so we don't call the related listener
      # and services
      allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original
      allow(ActiveSupport::Notifications).to receive(:instrument)
        .with("ofn.payment_transition", any_args).and_return(nil)

      allow(order).to receive_message_chain(:line_items, :empty?).and_return(false)
      allow(order).to receive_messages total: 100
      stub_request(:get, "https://api.stripe.com/v1/payment_intents/12345").
        to_return(status: 200, body: payment_authorised)
      stub_request(:post, "https://api.stripe.com/v1/payment_intents/12345/capture").
        to_return(status: 200, body: capture_successful)
    end

    it 'processes all payments' do
      allow(order).to receive(:pending_payments).and_return([payment1, payment2])

      order.process_payments!
      updater.update_payment_state
      expect(order.payment_state).to eq 'paid'

      expect(payment1).to be_completed
      expect(payment2).to be_completed
    end

    it 'does not go over total for order' do
      allow(order).to receive(:pending_payments).and_return([payment1, payment2, payment3])

      order.process_payments!
      updater.update_payment_state
      expect(order.payment_state).to eq 'paid'

      expect(payment1).to be_completed
      expect(payment2).to be_completed
      expect(payment3).to be_checkout
    end

    it "does not use failed payments" do
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
        expect(zero_payment.captured_at).not_to be_nil
      end
    end

    private

    def payment_intent(amount, status)
      JSON.generate(
        object: "payment_intent",
        amount:,
        status:,
        charges: { data: [{ id: "ch_1234", amount: }] },
        id: "12345",
        livemode: false
      )
    end
  end
end
