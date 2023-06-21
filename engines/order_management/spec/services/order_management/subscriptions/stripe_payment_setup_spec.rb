# frozen_string_literal: true

require 'spec_helper'

module OrderManagement
  module Subscriptions
    describe StripePaymentSetup do
      let(:order) { create(:order) }
      let(:payment_setup) { OrderManagement::Subscriptions::StripePaymentSetup.new(order) }

      describe "#call!" do
        context "when no pending payments are present" do
          before do
            allow(order).to receive(:pending_payments).once { [] }
          end

          it "does nothing" do
            expect(payment_setup.call!).to eq nil
          end
        end

        context "when a payment is present" do
          let(:payment) { create(:payment, payment_method: payment_method, amount: 10) }

          before { allow(order).to receive(:pending_payments).once { [payment] } }

          context "when the payment method is not a stripe payment method" do
            let(:payment_method) { create(:payment_method) }

            it "returns the pending payment with no change" do
              expect(payment).to_not receive(:update)
              expect(payment_setup.call!).to eq payment
            end
          end

          context "when the payment method is a stripe payment method" do
            let(:payment_method) { create(:stripe_sca_payment_method) }

            context "and the card is already set (the payment source is a credit card)" do
              it "returns the pending payment with no change" do
                expect(payment).to_not receive(:update)
                expect(payment_setup.call!).to eq payment
              end
            end

            context "and the card is not set (the payment source is not a credit card)" do
              before { payment.update_attribute :source, nil }

              context "and no default credit card has been saved by the customer" do
                before do
                  allow(order).to receive(:user) { instance_double(Spree::User, default_card: nil) }
                end

                it "adds an error to the order and does not update the payment" do
                  payment_setup.call!

                  expect(payment).to_not receive(:update)
                  expect(payment_setup.call!).to eq payment
                  expect(order.errors[:base].first).to eq "There are no authorised " \
                                                          "credit cards available to charge"
                end
              end

              context "and a default credit card has been saved by the customer" do
                let(:saved_credit_card) { create(:credit_card) }

                before do
                  allow(order).to receive(:user) {
                    instance_double(Spree::User, default_card: saved_credit_card)
                  }
                end

                context "but the customer has not authorised the shop to charge credit cards" do
                  before do
                    allow(order).to receive(:customer) {
                      instance_double(Customer, allow_charges?: false)
                    }
                  end

                  it "adds an error to the order and does not update the payment" do
                    payment_setup.call!

                    expect(payment).to_not receive(:update)
                    expect(payment_setup.call!).to eq payment
                    expect(order.errors[:base].first).to eq "There are no authorised " \
                                                            "credit cards available to charge"
                  end
                end

                context "and the customer has authorised the shop to charge credit cards" do
                  before do
                    allow(order).to receive(:customer) {
                      instance_double(Customer, allow_charges?: true)
                    }
                  end

                  it "uses the saved credit card as the source for the payment" do
                    payment_setup.call!
                    expect(payment.source).to eq saved_credit_card
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
