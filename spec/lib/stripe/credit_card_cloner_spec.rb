# frozen_string_literal: true

require 'spec_helper'
require 'stripe/credit_card_cloner'

module Stripe
  describe CreditCardCloner do
    let!(:user) { create(:user, email: "jumping.jane@example.com") }
    let!(:enterprise) { create(:enterprise) }

    let(:secret) { ENV.fetch('STRIPE_SECRET_TEST_API_KEY', nil) }

    describe "#find_or_clone", :vcr, :stripe_version do
      include StripeStubs

      before { Stripe.api_key = secret }

      let!(:customer_id) { ENV.fetch('STRIPE_CUSTOMER', nil) }

      let!(:stripe_account_id) { ENV.fetch('STRIPE_ACCOUNT', nil) }

      let!(:stripe_account) {
        create(:stripe_account, enterprise:, stripe_user_id: stripe_account_id)
      }

      let(:credit_card) { create(:credit_card, gateway_payment_profile_id: pm_card.id, user:) }

      let(:pm_card) {
        Stripe::PaymentMethod.create(
          {
            type: 'card',
            card: {
              number: '4242424242424242',
              exp_month: 8,
              exp_year: 2026,
              cvc: '314',
            },
          },
        )
      }

      let!(:connected_account) do
        Stripe::Account.create({
                                 type: 'standard',
                                 country: 'AU',
                                 email: 'jumping.jack@example.com'
                               })
      end

      let!(:cloner) { Stripe::CreditCardCloner.new(credit_card, connected_account.id) }

      context "when called with a card without a customer (one time usage card)" do
        let!(:payment_method_id) { pm_card.id }

        it "clones the payment method only" do
          customer_id, new_payment_method_id = cloner.find_or_clone

          expect(payment_method_id).not_to eq new_payment_method_id
          expect(customer_id).to eq nil
        end
      end

      xcontext "when called with a valid customer and payment_method" do
        before do
          stub_request(:post, "https://api.stripe.com/v1/payment_methods")
            .with(body: { customer: customer_id, payment_method: payment_method_id },
                  headers: { 'Stripe-Account' => stripe_account_id })
            .to_return(payment_method_response_mock)

          credit_card.update_attribute :gateway_customer_profile_id, customer_id
        end

        it "clones both the payment method and the customer" do
          customer_id, payment_method_id = cloner.find_or_clone

          expect(payment_method_id).to eq new_payment_method_id
          expect(customer_id).to eq new_customer_id
        end
      end
    end
  end
end
