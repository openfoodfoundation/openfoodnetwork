require 'spec_helper'

describe Spree::Admin::PaymentMethodsController do
  context "Requesting provider preference fields" do
    let(:user) do
      user = create(:user)
      user.spree_roles << Spree::Role.find_or_create_by_name!('admin')
      user
    end

    let(:payment_method) { create(:payment_method) }

    before do
      controller.stub spree_current_user: user
    end

    context "without an altered provider type" do
      it "renders provider settings with same payment method" do
        spree_get :show_provider_preferences, {
          id: payment_method.id,
          provider_type: "Spree::PaymentMethod::Check"
        }
        Spree::PaymentMethod.find(payment_method.id).should == payment_method
        response.should render_template partial: '_provider_settings'
      end
    end

    context "with an altered provider type" do
      it "renders provider settings with a different payment method" do
        spree_get :show_provider_preferences, {
          id: payment_method.id,
          provider_type: "Spree::Gateway::Bogus"
        }
        Spree::PaymentMethod.find(payment_method.id).should_not == payment_method
        response.should render_template partial: '_provider_settings'
      end
    end
  end
end