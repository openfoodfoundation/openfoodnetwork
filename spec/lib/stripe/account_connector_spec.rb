# frozen_string_literal: true

require 'spec_helper'
require 'stripe/account_connector'
require 'stripe/oauth'
require 'net/http'

module Stripe
  describe AccountConnector do
    describe "create_account" do
      let(:user) { create(:user, email: "apple.producer@example.com") }
      let(:enterprise) { create(:enterprise) }
      let(:client_id) { ENV.fetch('STRIPE_CLIENT_ID', nil) }
      let(:redirect_uri) { 'localhost' }

      let(:payload) { { "junk" => "Ssfs" } }
      let(:state) { JWT.encode(payload, Openfoodnetwork::Application.config.secret_token) }
      let(:params) { { "state" => state } }
      let(:connector) { AccountConnector.new(user, params) }

      context "when the connection was cancelled by the user" do
        before do
          params[:action] = "connect_callback"
          params[:error] = "access_denied"
        end

        it "returns false and does not create a new StripeAccount" do
          binding.pry
          expect do
            expect(connector.create_account).to be false
          end.not_to change { StripeAccount.count }
        end
      end

      context "when the connection was not cancelled by the user" do
        context "when params have no 'code' key" do
          it "raises a StripeError" do
            expect do
              expect{ connector.create_account }.to raise_error StripeError
            end.not_to change { StripeAccount.count }
          end
        end

        context "when params have a 'code' key" do
          before { params["code"] = 'code' }

          context "and the decoded state param doesn't contain an 'enterprise_id' key" do
            it "raises an AccessDenied error" do
              expect do
                expect{ connector.create_account }.to raise_error CanCan::AccessDenied
              end.not_to change { StripeAccount.count }
            end
          end

          context "and the decoded state param contains an 'enterprise_id' key", :vcr, :stripe_version do
            let(:payload) { { enterprise_id: enterprise.permalink } }
            let(:token_response) {
              { "stripe_user_id" => "some_user_id", "stripe_publishable_key" => "some_key" }
            }

            context "but the user doesn't manage own or manage the corresponding enterprise" do
              it "makes a request to cancel the Stripe connection and raises an error" do

                expect(OAuth).to receive(:deauthorize).with(stripe_user_id: "some_user_id")
                expect do
                  expect{ connector.create_account }.to raise_error CanCan::AccessDenied
                end.not_to change { StripeAccount.count }
              end
            end

            context "and the user manages the corresponding enterprise" do
                let(:uri) {
                 'https://connect.stripe.com/oauth/authorize?response_type=code&client_id=#{client_id}&scope=read_write'
               }
              before do
                user.enterprise_roles.create(enterprise:)
              end

              it "raises no errors" do
                uri = URI()
                params = { :api_key => Stripe.api_key }
                uri.query = URI.encode_www_form(params)
                res = Net::HTTP.get_response(uri)
                
                puts res.body if res.is_a?(Net::HTTPSuccess)

                expect(OAuth).not_to receive(:deauthorize)
                connector.create_account
              end

              it "allows creations of a new Stripe Account from the callback params" do
                expect{ connector.create_account }.to change { StripeAccount.count }.by(1)
                account = StripeAccount.last
                expect(account.stripe_user_id).to eq "some_user_id"
                expect(account.stripe_publishable_key).to eq "some_key"
              end
            end

            context "and the user owns the corresponding enterprise" do
              let(:user) { enterprise.owner }

              it "raises no errors" do
                expect(OAuth).not_to receive(:deauthorize)
                connector.create_account
              end

              it "allows creations of a new Stripe Account from the callback params" do
                binding.pry
                expect{ connector.create_account }.to change { StripeAccount.count }.by(1)
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
