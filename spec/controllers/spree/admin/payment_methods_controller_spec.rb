require 'spec_helper'

describe Spree::Admin::PaymentMethodsController do
  context "Requesting provider preference fields" do
    let(:user) do
      user = create(:user)
      user.spree_roles << Spree::Role.find_or_create_by_name!('admin')
      user
    end

    before do
      controller.stub spree_current_user: user
    end

    context "on an existing payment method" do
      let(:payment_method) { create(:payment_method) }

      context "without an altered provider type" do
        it "renders provider settings with same payment method" do
          spree_get :show_provider_preferences, {
            pm_id: payment_method.id,
            provider_type: "Spree::PaymentMethod::Check"
          }
          expect(assigns(:payment_method)).to eq payment_method
          expect(response).to render_template partial: '_provider_settings'
        end
      end

      context "with an altered provider type" do
        it "renders provider settings with a different payment method" do
          spree_get :show_provider_preferences, {
            pm_id: payment_method.id,
            provider_type: "Spree::Gateway::Bogus"
          }
          expect(assigns(:payment_method)).not_to eq payment_method
          expect(response).to render_template partial: '_provider_settings'
        end
      end
    end

    context "on a new payment method" do
      it "renders provider settings with a new payment method of type" do
        spree_get :show_provider_preferences, {
          pm_id: "",
          provider_type: "Spree::Gateway::Bogus"
        }
        expect(assigns(:payment_method)).to be_a_new Spree::Gateway::Bogus
        expect(response).to render_template partial: '_provider_settings'
      end
    end
  end
end