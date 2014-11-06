require 'spec_helper'

describe EnterpriseConfirmationsController do
  include AuthenticationWorkflow
  let!(:user) { create_enterprise_user( enterprise_limit: 10 ) }
  let!(:unconfirmed_enterprise) { create(:distributor_enterprise, confirmed_at: nil, owner: user) }
  let!(:confirmed_enterprise) { create(:distributor_enterprise, owner: user) }
  let!(:unowned_enterprise) { create(:distributor_enterprise) }

  before do
    controller.stub spree_current_user: user
    @request.env["devise.mapping"] = Devise.mappings[:enterprise]
  end

  context "confirming an enterprise" do
    it "that has already been confirmed" do
      spree_get :show, confirmation_token: confirmed_enterprise.confirmation_token
      expect(response).to redirect_to spree.admin_path
      expect(flash[:error]).to eq I18n.t('devise.enterprise_confirmations.enterprise.not_confirmed')
    end

    it "that has not already been confirmed" do
      spree_get :show, confirmation_token: unconfirmed_enterprise.confirmation_token
      expect(response).to redirect_to spree.admin_path
      expect(flash[:success]).to eq I18n.t('devise.enterprise_confirmations.enterprise.confirmed')
    end
  end

  context "requesting confirmation instructions to be resent" do
    it "when the user owns the enterprise" do
      spree_post :create, { enterprise: { id: unconfirmed_enterprise.id, email: unconfirmed_enterprise.email } }
      expect(response).to redirect_to spree.admin_path
      expect(flash[:success]).to eq I18n.t('devise.enterprise_confirmations.enterprise.confirmation_sent')
    end

    it "when the user does not own the enterprise" do
      spree_post :create, { enterprise: { id: unowned_enterprise.id, email: unowned_enterprise.email } }
      expect(response).to redirect_to spree.unauthorized_path
      expect(flash[:error]).to eq "Authorization Failure"
    end
  end
end