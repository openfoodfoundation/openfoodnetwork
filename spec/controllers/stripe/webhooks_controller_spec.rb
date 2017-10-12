require 'spec_helper'

describe Stripe::WebhooksController do
  describe "#create" do
    let(:params) do
      {
        "format" => "json",
        "id" => "evt_123",
        "object" => "event",
        "data" => { "object" => { "id" => "ca_9B" } },
        "type" => "account.application.authorized",
        "account" => "webhook_id1"
      }
    end

    context "when an event with an unknown type is received" do
      it "responds with a 202" do
        post 'create', params
        expect(response.status).to eq 202
      end
    end

    describe "when an account.application.deauthorized event is received" do
      let!(:stripe_account) { create(:stripe_account, stripe_user_id: "webhook_id") }
      before do
        params["type"] = "account.application.deauthorized"
      end

      context "when the stripe_account id on the event does not match any known accounts" do
        it "doesn't delete any Stripe accounts, responds with 204" do
          post 'create', params
          expect(response.status).to eq 204
          expect(StripeAccount.all).to include stripe_account
        end
      end

      context "when the stripe_account id on the event matches a known account" do
        before { params["account"] = "webhook_id" }

        it "deletes Stripe accounts in response to a webhook" do
          post 'create', params
          expect(response.status).to eq 200
          expect(StripeAccount.all).not_to include stripe_account
        end
      end
    end
  end
end
