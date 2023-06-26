# frozen_string_literal: true

require 'spec_helper'

describe Admin::StripeConnectSettingsController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:admin_user) }

  around do |example|
    original_stripe_connect_enabled = Spree::Config[:stripe_connect_enabled]
    example.run
    Spree::Config[:stripe_connect_enabled] = original_stripe_connect_enabled
  end

  describe "edit" do
    context "as an enterprise user" do
      before { allow(controller).to receive(:spree_current_user) { user } }

      it "does not allow access" do
        get :edit
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "as super admin" do
      before do
        Spree::Config.set(stripe_connect_enabled: true)
        allow(controller).to receive(:spree_current_user) { admin }
      end

      context "when a Stripe API key is not set" do
        before do
          Stripe.api_key = nil
        end

        it "sets the account status to :empty_api_key_error_html" do
          get :edit
          expect(assigns(:stripe_account)[:status]).to eq :empty_api_key_error_html
          expect(assigns(:settings).stripe_connect_enabled).to be true
        end
      end

      context "when a Stripe API key is set" do
        before do
          Stripe.api_key = "sk_test_xxxx"
        end

        context "and the request to retrieve Stripe account info fails" do
          before do
            stub_request(:get, "https://api.stripe.com/v1/account").
              to_return(status: 401,
                        body: "{\"error\": {\"message\": \"Invalid API Key provided: " \
                              "sk_test_****xxxx\"}}")
          end

          it "sets the account status to :auth_fail_error" do
            get :edit
            expect(assigns(:stripe_account)[:status]).to eq :auth_fail_error
            expect(assigns(:settings).stripe_connect_enabled).to be true
          end
        end

        context "and the request to retrieve Stripe account info succeeds" do
          before do
            stub_request(:get, "https://api.stripe.com/v1/account").
              to_return(status: 200, body: "{ \"id\": \"acct_1234\", \"business_name\": \"OFN\" }")
          end

          it "sets the account status to :ok, loads settings into Struct" do
            get :edit
            expect(assigns(:stripe_account)[:status]).to eq :ok
            expect(assigns(:obfuscated_secret_key)).to eq "sk_test_****xxxx"
            expect(assigns(:settings).stripe_connect_enabled).to be true
          end
        end
      end
    end
  end

  describe "update" do
    let(:params) { { settings: { stripe_connect_enabled: false } } }

    context "as an enterprise user" do
      before { allow(controller).to receive(:spree_current_user) { user } }

      it "does not allow access" do
        get :update, params: params
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "as super admin" do
      before do
        allow(controller).to receive(:spree_current_user) { admin }
        Spree::Config.set(stripe_connect_enabled: true)
      end

      it "sets global config to the specified values" do
        expect(Spree::Config.stripe_connect_enabled).to be true
        get :update, params: params
        expect(Spree::Config.stripe_connect_enabled).to be false
      end
    end
  end
end
