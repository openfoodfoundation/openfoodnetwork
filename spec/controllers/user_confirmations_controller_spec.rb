require 'spec_helper'

describe UserConfirmationsController do
  include AuthenticationWorkflow
  let!(:user) { create_enterprise_user }
  let!(:confirmed_user) { create_enterprise_user(confirmed_at: nil) }
  let!(:unconfirmed_user) { create_enterprise_user(confirmed_at: nil) }
  let!(:confirmed_token) { confirmed_user.confirmation_token }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
    confirmed_user.confirm!
  end

  context "confirming a user" do
    context "that has already been confirmed" do

      before do
        spree_get :show, confirmation_token: confirmed_token
      end

      it "redirects the user to login" do
        expect(response).to redirect_to login_path
        expect(flash[:error]).to eq I18n.t('devise.user_confirmations.spree_user.not_confirmed')
      end
    end

    context "that has not been confirmed" do
      it "redirects the user to login" do
        spree_get :show, confirmation_token: unconfirmed_user.confirmation_token
        expect(response).to redirect_to login_path
        expect(flash[:success]).to eq I18n.t('devise.user_confirmations.spree_user.confirmed')
      end

      it "confirms the user" do
        spree_get :show, confirmation_token: unconfirmed_user.confirmation_token
        expect(unconfirmed_user.reload.confirmed_at).not_to eq(nil)
      end
    end
  end

  context "requesting confirmation instructions to be resent" do
    it "redirects the user to login" do
      spree_post :create, { spree_user: { email: unconfirmed_user.email } }
      expect(response).to redirect_to login_path
      expect(flash[:success]).to eq I18n.t('devise.user_confirmations.spree_user.confirmation_sent')
    end

    it "sends the confirmation email" do
      expect do
        spree_post :create, { spree_user: { email: unconfirmed_user.email } }
      end.to enqueue_job Delayed::PerformableMethod
      expect(Delayed::Job.last.payload_object.method_name).to eq(:send_confirmation_instructions_without_delay)
    end
  end
end
