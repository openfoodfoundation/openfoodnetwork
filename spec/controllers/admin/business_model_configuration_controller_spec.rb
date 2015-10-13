require 'spec_helper'

describe Admin::AccountsAndBillingSettingsController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:admin_user) }

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

      it "allows access" do
        spree_get :edit
        expect(response).to_not redirect_to spree.unauthorized_path
      end
    end
  end
end
