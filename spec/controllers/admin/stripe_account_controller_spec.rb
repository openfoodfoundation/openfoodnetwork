require 'spec_helper'

describe Admin::StripeAccountsController, type: :controller do

  describe "destroy_from_webhook" do
    it "deletes Stripe accounts in response to a webhook" do
      # https://stripe.com/docs/api#retrieve_event
      allow(controller).to receive(:fetch_event_from_stripe)
        .and_return(Stripe::Event.construct_from({"id"=>"evt_wrfwg4323fw",
                     "object"=>"event",
                     "api_version"=>nil,
                     "created"=>1484870684,
                     "data"=>
                      {"object"=>
                        {"id"=>"application_id",
                         "object"=>"application",
                         "name"=>"Open Food Network UK"}},
                     "livemode"=>false,
                     "pending_webhooks"=>1,
                     "request"=>nil,
                     "type"=>"account.application.deauthorized",
                     "user_id"=>"webhook_id"}))
      account = create(:stripe_account, stripe_user_id: "webhook_id")
      expect(Stripe::Event).not_to receive(:retrieve) # should not retrieve direct for a deauth event
      post 'destroy_from_webhook', {"id"=>"evt_wrfwg4323fw",
                                     "object"=>"event",
                                     "api_version"=>nil,
                                     "created"=>1484870684,
                                     "data"=>
                                      {"object"=>
                                        {"id"=>"ca_9ByaSyyyXj5O73DWisU0KLluf0870Vro",
                                         "object"=>"application",
                                         "name"=>"Open Food Network UK"}},
                                     "livemode"=>false,
                                     "pending_webhooks"=>1,
                                     "request"=>nil,
                                     "type"=>"account.application.deauthorized",
                                     "user_id"=>"webhook_id"}
      expect(StripeAccount.all).not_to include account
    end
  end

  describe "verifying stripe account status with Stripe" do
    let(:enterprise) { create(:distributor_enterprise) }
    let(:params) { { format: :json } }

    before do
      Stripe.api_key = "sk_test_12345"
      Spree::Config.set({stripe_connect_enabled: false})
    end

    context "where I don't manage the specified enterprise" do
      let(:user) { create(:user) }
      let(:enterprise2) { create(:enterprise) }
      before do
        user.owned_enterprises << enterprise2
        params.merge!({enterprise_id: enterprise.id})
        allow(controller).to receive(:spree_current_user) { user }
      end

      it "redirects to unauthorized" do
        spree_get :status, params
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "where I manage the specified enterprise" do
      before do
        params.merge!({enterprise_id: enterprise.id})
        allow(controller).to receive(:spree_current_user) { enterprise.owner }
      end

      context "but Stripe is not enabled" do
        it "returns with a status of 'stripe_disabled'" do
          spree_get :status, params
          json_response = JSON.parse(response.body)
          expect(json_response["status"]).to eq "stripe_disabled"
        end
      end

      context "and Stripe is enabled" do
        before { Spree::Config.set({stripe_connect_enabled: true}) }

        context "but it has no associated stripe account" do
          it "returns with a status of 'account_missing'" do
            spree_get :status, params
            json_response = JSON.parse(response.body)
            expect(json_response["status"]).to eq "account_missing"
          end
        end

        context "and it has an associated stripe account" do
          let!(:account) { create(:stripe_account, stripe_user_id: "acc_123", enterprise: enterprise) }

          context "which has been revoked or does not exist" do
            before do
              stub_request(:get, "https://api.stripe.com/v1/accounts/acc_123").to_return(status: 404)
            end

            it "returns with a status of 'access_revoked'" do
              spree_get :status, params
              json_response = JSON.parse(response.body)
              expect(json_response["status"]).to eq "access_revoked"
            end
          end

          context "which is connected" do
            let(:stripe_account_mock) { {
              id: "acc_123",
              business_name: "My Org",
              charges_enabled: true,
              some_other_attr: "something"
            } }

            before do
              stub_request(:get, "https://api.stripe.com/v1/accounts/acc_123").to_return(body: JSON.generate(stripe_account_mock))
            end

            it "returns with a status of 'connected'" do
              spree_get :status, params
              json_response = JSON.parse(response.body)
              expect(json_response["status"]).to eq "connected"
              # serializes required attrs
              expect(json_response["business_name"]).to eq "My Org"
              # ignores other attrs
              expect(json_response["some_other_attr"]).to be nil
            end
          end
        end
      end
    end
  end
end
