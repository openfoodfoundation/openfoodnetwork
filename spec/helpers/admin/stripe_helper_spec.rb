require 'spec_helper'

describe Admin::StripeHelper do
  let!(:enterprise) { create(:enterprise) }
  let!(:stripe_account) { create(:stripe_account, enterprise: enterprise) }
  it "calls the Stripe API to get a token" do
    expect(Admin::StripeHelper.client.auth_code).to receive(:get_token).with("abc",{scope: "read_write"})
    helper.get_stripe_token("abc")
  end

  it "calls the Stripe API for authorization, passing the enterprise in the state param" do
    expect(Admin::StripeHelper.client.auth_code).to receive(:authorize_url).with({state: {enterprise_id: "enterprise-permalink"}})
    helper.authorize_stripe("enterprise-permalink")
  end

  context "Disconnecting an account" do
    it "doesn't destroy the database record if the Stripe API disconnect failed" do
      Admin::StripeHelper.client
        .deauthorize(stripe_account.stripe_user_id)
        .stub(:deauthorize_request)
        .and_return(nil)

      deauthorize_stripe(stripe_account.id)
      expect(StripeAccount.all).to include(stripe_account)
    end

    it "destroys the record if the Stripe API disconnect succeeds" do
      Admin::StripeHelper.client
        .deauthorize(stripe_account.stripe_user_id)
        .stub(:deauthorize_request)
        .and_return("something truthy")

      deauthorize_stripe(stripe_account.id)
      expect(StripeAccount.all).not_to include(stripe_account)
    end

  end
end
