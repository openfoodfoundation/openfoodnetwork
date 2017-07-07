require 'spec_helper'
require 'stripe/oauth'

describe StripeAccount do
  describe "deauthorize_and_destroy" do
    let!(:enterprise) { create(:enterprise) }
    let!(:enterprise2) { create(:enterprise) }
    let!(:stripe_account) { create(:stripe_account, enterprise: enterprise) }

    context "when the Stripe API disconnect fails" do
      before do
        Stripe::OAuth.client
                     .deauthorize(stripe_account.stripe_user_id)
                     .stub(:deauthorize_request)
                     .and_return(nil)
      end

      it "doesn't destroy the record" do
        stripe_account.deauthorize_and_destroy
        expect(StripeAccount.all).to include(stripe_account)
      end
    end

    context "when the Stripe API disconnect succeeds" do
      before do
        Stripe::OAuth.client
                     .deauthorize(stripe_account.stripe_user_id)
                     .stub(:deauthorize_request)
                     .and_return("something truthy")
      end

      it "destroys the record" do
        stripe_account.deauthorize_and_destroy
        expect(StripeAccount.all).not_to include(stripe_account)
      end
    end

    context "if the account is also associated with another Enterprise" do
      let!(:another_stripe_account) { create(:stripe_account, enterprise: enterprise2, stripe_user_id: stripe_account.stripe_user_id) }

      it "Doesn't make a Stripe API disconnection request " do
        expect(Stripe::OAuth.client.deauthorize(stripe_account.stripe_user_id)).not_to receive(:deauthorize_request)
        stripe_account.deauthorize_and_destroy
      end
    end
  end
end
