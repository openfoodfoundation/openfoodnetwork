require 'spec_helper'

describe EnterpriseConfirmationsController, type: :controller do
  include AuthenticationWorkflow
  let!(:user) { create_enterprise_user( enterprise_limit: 10 ) }
  let!(:unconfirmed_enterprise) { create(:distributor_enterprise, confirmed_at: nil, owner: user) }
  let!(:confirmed_enterprise) { create(:distributor_enterprise, confirmed_at: nil, owner: user) }
  let!(:confirmed_token) { confirmed_enterprise.confirmation_token }
  let!(:unowned_enterprise) { create(:distributor_enterprise) }

  before do
    controller.stub spree_current_user: user
    @request.env["devise.mapping"] = Devise.mappings[:enterprise]
    confirmed_enterprise.confirm!
  end

  context "confirming an enterprise" do
    context "that has already been confirmed" do

      before do
        spree_get :show, confirmation_token: confirmed_token
      end

      it "redirects the user to admin" do
        expect(response).to redirect_to spree.admin_path
        expect(flash[:error]).to eq I18n.t('devise.enterprise_confirmations.enterprise.not_confirmed')
      end
    end

    context "that has not been confirmed" do
      context "where the enterprise contact email maps to an existing user account" do
        before do
          unconfirmed_enterprise.update_attribute(:email, user.email)
        end

        it "redirects the user to admin" do
          spree_get :show, confirmation_token: unconfirmed_enterprise.confirmation_token
          expect(response).to redirect_to spree.admin_path
          expect(flash[:success]).to eq I18n.t('devise.enterprise_confirmations.enterprise.confirmed')
        end
      end

      context "where the enterprise contact email doesn't map to an existing user account" do
        let(:new_user) { create_enterprise_user }

        before do
          unconfirmed_enterprise.update_attribute(:email, 'random@email.com')
          allow(Spree::User).to receive(:create) { new_user }
          allow(new_user).to receive(:reset_password_token) { "token" }
        end

        it "redirects to the user to reset their password" do
          expect(new_user).to receive(:send_reset_password_instructions_without_delay).and_call_original
          spree_get :show, confirmation_token: unconfirmed_enterprise.confirmation_token
          expect(response).to redirect_to spree.edit_spree_user_password_path(new_user, :reset_password_token => "token", return_to: spree.admin_path)
          expect(flash[:success]).to eq I18n.t('devise.enterprise_confirmations.enterprise.confirmed')
          expect(unconfirmed_enterprise.users(:reload)).to include new_user
        end
      end
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
