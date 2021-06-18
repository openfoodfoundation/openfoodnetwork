# frozen_string_literal: true

require 'spec_helper'
require 'stripe/oauth'

describe StripeAccount do
  describe "deauthorize_and_destroy" do
    let!(:enterprise) { create(:enterprise) }
    let!(:enterprise2) { create(:enterprise) }
    let(:client_id) { 'ca_abc123' }
    let(:stripe_user_id) { 'acct_abc123' }
    let!(:stripe_account) {
      create(:stripe_account, enterprise: enterprise, stripe_user_id: stripe_user_id)
    }

    before do
      Stripe.api_key = "sk_test_12345"
      Stripe.client_id = client_id
    end

    context "when the Stripe API disconnect fails" do
      before do
        stub_request(:post, "https://connect.stripe.com/oauth/deauthorize").
          with(body: { "client_id" => client_id, "stripe_user_id" => stripe_user_id }).
          to_return(status: 400, body: JSON.generate(error: 'invalid_grant',
                                                     error_description: "Some Message"))
      end

      it "destroys the record and notifies Bugsnag" do
        expect(Bugsnag).to receive(:notify)
        stripe_account.deauthorize_and_destroy
        expect(StripeAccount.all).to_not include(stripe_account)
      end
    end

    context "when the Stripe API disconnect succeeds" do
      before do
        stub_request(:post, "https://connect.stripe.com/oauth/deauthorize").
          with(body: { "client_id" => client_id, "stripe_user_id" => stripe_user_id }).
          to_return(status: 200, body: JSON.generate(stripe_user_id: stripe_user_id))
      end

      it "destroys the record" do
        stripe_account.deauthorize_and_destroy
        expect(StripeAccount.all).not_to include(stripe_account)
      end
    end

    context "if the account is also associated with another Enterprise" do
      let!(:another_stripe_account) {
        create(:stripe_account, enterprise: enterprise2, stripe_user_id: stripe_user_id)
      }

      it "Doesn't make a Stripe API disconnection request " do
        expect(Stripe::OAuth).to_not receive(:deauthorize)
        stripe_account.deauthorize_and_destroy
        expect(StripeAccount.all).not_to include(stripe_account)
      end
    end
  end
end
