# frozen_string_literal: true

require 'spec_helper'
require 'stripe/credit_card_cloner'

module Stripe
  describe CreditCardCloner do
    describe "#clone" do
      let(:cloner) { Stripe::CreditCardCloner.new }

      let(:customer_id) { "cus_A123" }
      let(:card_id) { "card_1234" }
      let(:new_customer_id) { "cus_A456" }
      let(:new_payment_method_id) { "pm_4567" }
      let(:stripe_account_id) { "acct_456" }
      let(:customer_response_mock) { { status: 200, body: customer_response_body } }
      let(:payment_method_response_mock) { { status: 200, body: payment_method_response_body } }

      let(:credit_card) { create(:credit_card, user: create(:user)) }

      before do
        allow(Stripe).to receive(:api_key) { "sk_test_12345" }

        stub_request(:post, "https://api.stripe.com/v1/payment_methods")
          .with(basic_auth: ["sk_test_12345", ""])
          .to_return(payment_method_response_mock)

        stub_request(:post, "https://api.stripe.com/v1/customers")
          .with(basic_auth: ["sk_test_12345", ""], body: { email: credit_card.user.email })
          .to_return(customer_response_mock)
      end

      context "when called with a credit_card with valid id (card_*)" do
        let(:payment_method_response_body) {
          JSON.generate(id: new_payment_method_id, default_card: card_id)
        }
        let(:customer_response_body) {
          JSON.generate(id: customer_id, default_card: card_id)
        }

        it "clones the card successefully" do
          cloner.clone(credit_card, stripe_account_id)

          expect(credit_card.gateway_customer_profile_id).to eq new_customer_id
          expect(credit_card.gateway_payment_profile_id).to eq new_payment_method_id
        end
      end
    end
  end
end
