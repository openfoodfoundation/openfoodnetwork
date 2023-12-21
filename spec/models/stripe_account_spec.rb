# frozen_string_literal: true

require 'spec_helper'
require 'stripe/oauth'

describe StripeAccount do
  describe "deauthorize_and_destroy", :vcr, :stripe_version do
    let!(:enterprise) { create(:enterprise) }
    let!(:enterprise2) { create(:enterprise) }
    let(:client_id) { ENV.fetch('STRIPE_CLIENT_ID', nil) }
    let(:stripe_user_id) { ENV.fetch('STRIPE_ACCOUNT', nil) }
    let(:stripe_publishable_key) { ENV.fetch('STRIPE_PUBLIC_TEST_API_KEY', nil) }
    let(:secret) { ENV.fetch('STRIPE_SECRET_TEST_API_KEY', nil) }

    let!(:stripe_account) {
      create(:stripe_account, enterprise:, stripe_user_id:)
    }

    before do
      Stripe.api_key = secret
    end

    context "when the Stripe API disconnect fails" do
      before { Stripe.client_id = "bogus_client_id" }

      it "destroys the record and notifies Bugsnag" do
        # returns status 401
        expect(Bugsnag).to receive(:notify) # and receives Bugsnag notification
        expect {
          stripe_account.deauthorize_and_destroy
        }.to change(
          StripeAccount.where(stripe_user_id:), :count
        ).from(1).to(0)
      end
    end

    context "when the Stripe API disconnect succeeds" do
      let!(:connected_account) do
        Stripe::Account.create({
                                 type: 'standard',
                                 country: 'AU',
                                 email: 'jumping.jack@example.com'
                               })
      end

      before do
        Stripe.client_id = client_id
        stripe_account.update!(stripe_publishable_key:, stripe_user_id: connected_account.id)
      end

      it "destroys the record" do
        # returns status 200
        expect(Bugsnag).to_not receive(:notify) # and does not receive Bugsnag notification
        expect {
          stripe_account.deauthorize_and_destroy
        }.to change(
          StripeAccount.where(stripe_user_id: connected_account.id), :count
        ).from(1).to(0)
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
