require 'spec_helper'

describe StripeController do
  describe "#deauthorize" do
    let!(:stripe_account) { create(:stripe_account, stripe_user_id: "webhook_id") }
    let(:params) do
      {
        "format" => "json",
        "id" => "evt_123",
        "object" => "event",
        "data" => { "object" => { "id" => "ca_9B" } },
        "type" => "account.application.deauthorized",
        "account" => "webhook_id"
      }
    end

    it "deletes Stripe accounts in response to a webhook" do
      post 'deauthorize', params
      expect(response.status).to eq 200
      expect(response.body).to eq "Account webhook_id deauthorized"
      expect(StripeAccount.all).not_to include stripe_account
    end

    context "when the stripe_account id on the event does not match any known accounts" do
      before do
        params["account"] = "webhook_id1"
      end

      it "does nothing" do
        post 'deauthorize', params
        expect(response.status).to eq 204
        expect(StripeAccount.all).to include stripe_account
      end
    end

    context "when the event is not a deauthorize event" do
      before do
        params["type"] = "account.application.authorized"
      end

      it "does nothing" do
        post 'deauthorize', params
        expect(response.status).to eq 204
        expect(StripeAccount.all).to include stripe_account
      end
    end
  end
end
