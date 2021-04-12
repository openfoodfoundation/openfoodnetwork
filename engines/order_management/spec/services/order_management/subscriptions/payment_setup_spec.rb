# frozen_string_literal: true

require 'spec_helper'

module OrderManagement
  module Subscriptions
    describe PaymentSetup do
      let(:order) { create(:order) }
      let(:payment_setup) { OrderManagement::Subscriptions::PaymentSetup.new(order) }

      describe "#call!" do
        let!(:payment) { create(:payment, amount: 10) }

        context "when no pending payments are present" do
          let(:payment_method) { create(:payment_method) }
          let(:subscription) { double(:subscription, payment_method_id: payment_method.id) }

          before do
            allow(order).to receive(:pending_payments).once { [] }
            allow(order).to receive(:new_outstanding_balance) { 5 }
            allow(order).to receive(:subscription) { subscription }
          end

          it "creates a new payment on the order" do
            expect{ payment_setup.call! }.to change(Spree::Payment, :count).by(1)
            expect(order.payments.first.amount).to eq 5
          end
        end

        context "when a payment is present" do
          before { allow(order).to receive(:pending_payments).once { [payment] } }

          context "when the payment total doesn't match the outstanding balance on the order" do
            before { allow(order).to receive(:new_outstanding_balance) { 5 } }

            it "updates the payment total to reflect the outstanding balance" do
              expect{ payment_setup.call! }.to change(payment, :amount).from(10).to(5)
            end
          end

          context "when the payment total matches the outstanding balance on the order" do
            before { allow(order).to receive(:new_outstanding_balance) { 10 } }

            it "does nothing" do
              expect{ payment_setup.call! }.to_not change(payment, :amount).from(10)
            end
          end
        end

        context "when more that one payment exists on the order" do
          let!(:payment1) { create(:payment, order: order) }
          let!(:payment2) { create(:payment, order: order) }

          before do
            allow(order).to receive(:new_outstanding_balance) { 7 }
            allow(order).to receive(:pending_payments).once { [payment1, payment2] }
          end

          it "updates the amount of the last payment to reflect the outstanding balance" do
            payment_setup.call!
            expect(payment1.amount).to eq 45.75
            expect(payment2.amount).to eq 7
          end
        end
      end
    end
  end
end
