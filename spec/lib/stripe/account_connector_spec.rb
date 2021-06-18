# frozen_string_literal: true

require 'spec_helper'
require 'stripe/account_connector'
require 'stripe/oauth'

module Stripe
  describe AccountConnector do
    describe "create_account" do
      let(:user) { create(:user) }
      let(:enterprise) { create(:enterprise) }
      let(:payload) { { "junk" => "Ssfs" } }
      let(:state) { JWT.encode(payload, Openfoodnetwork::Application.config.secret_token) }
      let(:params) { { "state" => state } }
      let(:connector) { AccountConnector.new(user, params) }

      before do
        Stripe.api_key = "sk_test_12345"
      end

      context "when the connection was cancelled by the user" do
        before do
          params[:action] = "connect_callback"
          params[:error] = "access_denied"
        end

        it "returns false and does not create a new StripeAccount" do
          expect do
            expect(connector.create_account).to be false
          end.to_not change(StripeAccount, :count)
        end
      end

      context "when the connection was not cancelled by the user" do
        context "when params have no 'code' key" do
          it "raises a StripeError" do
            expect do
              expect{ connector.create_account }.to raise_error StripeError
            end.to_not change(StripeAccount, :count)
          end
        end

        context "when params have a 'code' key" do
          before { params["code"] = 'code' }

          context "and the decoded state param doesn't contain an 'enterprise_id' key" do
            it "raises an AccessDenied error" do
              expect do
                expect{ connector.create_account }.to raise_error CanCan::AccessDenied
              end.to_not change(StripeAccount, :count)
            end
          end

          context "and the decoded state param contains an 'enterprise_id' key" do
            let(:payload) { { enterprise_id: enterprise.permalink } }
            let(:token_response) {
              { "stripe_user_id" => "some_user_id", "stripe_publishable_key" => "some_key" }
            }

            before do
              stub_request(:post, "https://connect.stripe.com/oauth/token").
                with(body: { "code" => "code", "grant_type" => "authorization_code" }).
                to_return(status: 200, body: JSON.generate(token_response) )
            end

            context "but the user doesn't manage own or manage the corresponding enterprise" do
              it "makes a request to cancel the Stripe connection and raises an error" do
                expect(OAuth).to receive(:deauthorize).with(stripe_user_id: "some_user_id")
                expect do
                  expect{ connector.create_account }.to raise_error CanCan::AccessDenied
                end.to_not change(StripeAccount, :count)
              end
            end

            context "and the user manages the corresponding enterprise" do
              before do
                user.enterprise_roles.create(enterprise: enterprise)
              end

              it "raises no errors" do
                expect(OAuth).to_not receive(:deauthorize)
                connector.create_account
              end

              it "allows creations of a new Stripe Account from the callback params" do
                expect{ connector.create_account }.to change(StripeAccount, :count).by(1)
                account = StripeAccount.last
                expect(account.stripe_user_id).to eq "some_user_id"
                expect(account.stripe_publishable_key).to eq "some_key"
              end
            end

            context "and the user owns the corresponding enterprise" do
              let(:user) { enterprise.owner }

              it "raises no errors" do
                expect(OAuth).to_not receive(:deauthorize)
                connector.create_account
              end

              it "allows creations of a new Stripe Account from the callback params" do
                expect{ connector.create_account }.to change(StripeAccount, :count).by(1)
                account = StripeAccount.last
                expect(account.stripe_user_id).to eq "some_user_id"
                expect(account.stripe_publishable_key).to eq "some_key"
              end
            end
          end
        end
      end
    end
  end
end
