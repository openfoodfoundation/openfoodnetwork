require 'spec_helper'

describe Stripe::CallbacksController, type: :controller do
  let(:enterprise) { create(:distributor_enterprise) }

  context "#index" do
    let(:params) { { id: enterprise.permalink } }
    let(:connector) { double(:connector) }

    before do
      allow(controller).to receive(:spree_current_user) { enterprise.owner }
      allow(Stripe::AccountConnector).to receive(:new) { connector }
    end

    context "when the connector.create_account raises a StripeError" do
      before do
        allow(connector).to receive(:create_account).and_raise Stripe::StripeError, "some error"
      end

      it "returns a 500 error" do
        spree_get :index, params
        expect(response.status).to be 500
      end
    end

    context "when the connector.create_account raises an AccessDenied error" do
      before do
        allow(connector).to receive(:create_account).and_raise CanCan::AccessDenied, "some error"
      end

      it "redirects to unauthorized" do
        spree_get :index, params
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "when the connector fails in creating a new stripe account record" do
      before { allow(connector).to receive(:create_account) { false } }

      context "when the user cancelled the connection" do
        before { allow(connector).to receive(:connection_cancelled_by_user?) { true } }

        it "renders a failure message" do
          allow(connector).to receive(:enterprise) { enterprise }
          spree_get :index, params
          expect(flash[:notice]).to eq I18n.t('admin.controllers.enterprises.stripe_connect_cancelled')
          expect(response).to redirect_to edit_admin_enterprise_path(enterprise, anchor: 'payment_methods')
        end
      end

      context "when some other error caused the failure" do
        before { allow(connector).to receive(:connection_cancelled_by_user?) { false } }

        it "renders a failure message" do
          allow(connector).to receive(:enterprise) { enterprise }
          spree_get :index, params
          expect(flash[:error]).to eq I18n.t('admin.controllers.enterprises.stripe_connect_fail')
          expect(response).to redirect_to edit_admin_enterprise_path(enterprise, anchor: 'payment_methods')
        end
      end
    end

    context "when the connector succeeds in creating a new stripe account record" do
      before { allow(connector).to receive(:create_account) { true } }

      it "redirects to the enterprise edit path" do
        allow(connector).to receive(:enterprise) { enterprise }
        spree_get :index, params
        expect(flash[:success]).to eq I18n.t('admin.controllers.enterprises.stripe_connect_success')
        expect(response).to redirect_to edit_admin_enterprise_path(enterprise, anchor: 'payment_methods')
      end
    end
  end
end
