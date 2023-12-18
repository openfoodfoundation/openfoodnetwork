# frozen_string_literal: true

require 'spec_helper'
require 'stripe/oauth'

describe StripeAccount do
  describe "deauthorize_and_destroy", :vcr, :stripe_version do
    let!(:enterprise) { create(:enterprise) }
    let!(:enterprise2) { create(:enterprise) }
    let(:client_id) { ENV.fetch('STRIPE_CLIENT_ID', nil) }
    let(:stripe_user_id) { ENV.fetch('STRIPE_ACCOUNT', nil) }

    let!(:stripe_account) {
      create(:stripe_account, enterprise:, stripe_user_id:)
    }

    let(:secret) { ENV.fetch('STRIPE_SECRET_TEST_API_KEY', nil) }

    before do
      Stripe.api_key = secret
    end

    context "when the Stripe API disconnect fails" do
      before { Stripe.client_id = "bogus_client_id" }

      it "destroys the record and notifies Bugsnag" do
        expect(Bugsnag).to receive(:notify)
        stripe_account.deauthorize_and_destroy
        expect(StripeAccount.all).to_not include(stripe_account)
      end
    end

    context "when the Stripe API disconnect succeeds" do
      before { Stripe.client_id = client_id }

      it "destroys the record" do
        stripe_account.deauthorize_and_destroy
        expect(StripeAccount.all).not_to include(stripe_account)
      end
    end

    context "if the account is also associated with another Enterprise" do
      let!(:another_stripe_account) {
        create(:stripe_account, enterprise: enterprise2, stripe_user_id:)
      }

      it "Doesn't make a Stripe API disconnection request " do
        expect(Stripe::OAuth).to_not receive(:deauthorize)
        stripe_account.deauthorize_and_destroy
        expect(StripeAccount.all).not_to include(stripe_account)
      end
    end
  end
end
