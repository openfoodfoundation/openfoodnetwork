require 'spec_helper'

describe Admin::StripeConnectSettingsController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:admin_user) }

  before do
    Spree::Config.set(stripe_connect_enabled: true)
  end

  describe "edit" do
    context "as an enterprise user" do
      before { allow(controller).to receive(:spree_current_user) { user } }

      it "does not allow access" do
        spree_get :edit
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "as super admin" do
      before { allow(controller).to receive(:spree_current_user) { admin } }

      context "when a Stripe API key is not set" do
        before { Stripe.api_key = nil }

        it "sets the account status to :empty_api_key" do
          spree_get :edit
          expect(assigns(:stripe_account)[:status]).to eq :empty_api_key
          expect(assigns(:settings).stripe_connect_enabled).to be true
        end
      end

      context "when a Stripe API key is set" do
        before { Stripe.api_key = "sk_test_xxxx" }

        context "and the request to retrieve Stripe account info fails" do
          before do
            stub_request(:get, "https://api.stripe.com/v1/account").
            to_return(:status => 401, :body => "{\"error\": {\"message\": \"Invalid API Key provided: sk_test_****xxxx\"}}")
          end

          it "sets the account status to :auth_fail" do
            spree_get :edit
            expect(assigns(:stripe_account)[:status]).to eq :auth_fail
            expect(assigns(:settings).stripe_connect_enabled).to be true
          end
        end

        context "and the request to retrieve Stripe account info succeeds" do
          before do
            stub_request(:get, "https://api.stripe.com/v1/account").
            to_return(:status => 200, :body => "{ \"id\": \"acct_1234\", \"business_name\": \"OFN\" }")
          end

          it "sets the account status to :ok, loads settings into Struct" do
            spree_get :edit
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
        spree_get :update, params
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "as super admin" do
      before {allow(controller).to receive(:spree_current_user) { admin } }

      it "sets global config to the specified values" do
        expect(Spree::Config.stripe_connect_enabled).to be true
        spree_get :update, params
        expect(Spree::Config.stripe_connect_enabled).to be false
      end
    end
  end
end
