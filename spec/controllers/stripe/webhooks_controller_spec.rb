require 'spec_helper'

describe Stripe::WebhooksController, type: :controller do
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

    context "when invalid json is provided" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise JSON::ParserError, "parsing failed"
      end

      it "responds with a 400" do
        post 'create', params
        expect(response.status).to eq 400
      end
    end

    context "when event signature verification fails" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise Stripe::SignatureVerificationError.new("verfication failed", "header")
      end

      it "responds with a 401" do
        post 'create', params
        expect(response.status).to eq 401
      end
    end

    context "when event signature verification succeeds" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event) { Stripe::Event.construct_from(params) }
      end

      describe "setting the response status" do
        let(:handler) { double(:handler) }
        before { allow(Stripe::WebhookHandler).to receive(:new) { handler } }

        context "when an unknown result is returned by the handler" do
          before { allow(handler).to receive(:handle) { :garbage } }

          it "falls back to 200" do
            post 'create', params
            expect(response.status).to eq 200
          end
        end

        context "when the result returned by the handler is :unknown" do
          before { allow(handler).to receive(:handle) { :unknown } }

          it "responds with 202" do
            post 'create', params
            expect(response.status).to eq 202
          end
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
end
