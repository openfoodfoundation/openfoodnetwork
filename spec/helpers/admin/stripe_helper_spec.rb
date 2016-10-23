require 'spec_helper'

describe Admin::StripeHelper do
  let!(:enterprise) { create(:enterprise) }
  let!(:enterprise2) { create(:enterprise) }
  let!(:stripe_account) { create(:stripe_account, enterprise: enterprise) }

  it "calls the Stripe API to get a token" do
    expect(Admin::StripeHelper.client.auth_code).to receive(:get_token).with("abc",{scope: "read_write"})
    helper.get_stripe_token("abc")
  end

  it "calls the Stripe API for authorization, passing appropriate JWT in the state param" do
    expect(Admin::StripeHelper.client.auth_code).to receive(:authorize_url).with({
      state: JWT.encode({enterprise_id: "enterprise-permalink"}, Openfoodnetwork::Application.config.secret_token)
    })
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

    it "Doesn't make a Stripe API disconnection request if the account is also associated with another Enterprise" do
      another_stripe_account = create(:stripe_account, enterprise: enterprise2, stripe_user_id: stripe_account.stripe_user_id)
      expect(Admin::StripeHelper.client.deauthorize(stripe_account.stripe_user_id)).not_to receive(:deauthorize_request)
      deauthorize_stripe(stripe_account.id)
    end

    it "encodes and decodes JWT" do
      jwt_decode(jwt_encode({test: "string"})).should eq({"test" => "string"})
    end

  end
end
