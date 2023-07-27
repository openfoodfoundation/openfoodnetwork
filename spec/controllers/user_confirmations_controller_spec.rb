# frozen_string_literal: true

require 'spec_helper'

describe UserConfirmationsController, type: :controller do
  let!(:user) { create(:user) }
  let!(:confirmed_user) { create(:user, confirmed_at: nil) }
  let!(:unconfirmed_user) { create(:user, confirmed_at: nil) }
  let!(:confirmed_token) { confirmed_user.confirmation_token }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
    confirmed_user.confirm
  end

  context "confirming a user" do
    context "that has already been confirmed" do
      before do
        spree_get :show, confirmation_token: confirmed_token
      end

      it "redirects the user to login" do
        expect(response).to redirect_to root_path(anchor: "/login", validation: "not_confirmed")
      end
    end

    context "that has not been confirmed" do
      it "confirms the user" do
        spree_get :show, confirmation_token: unconfirmed_user.confirmation_token
        expect(unconfirmed_user.reload.confirmed_at).not_to eq(nil)
      end

      it "redirects the user to #/login by default" do
        spree_get :show, confirmation_token: unconfirmed_user.confirmation_token
        expect(response).to redirect_to root_path(anchor: "/login", validation: "confirmed")
      end

      it "redirects to previous url, if present" do
        session[:confirmation_return_url] = producers_path(anchor: "#/login")
        spree_get :show, confirmation_token: unconfirmed_user.confirmation_token
        expect(response).to redirect_to producers_path(anchor: "#/login", validation: "confirmed")
      end

      it "redirects to previous url on /register path" do
        session[:confirmation_return_url] =
          registration_path(anchor: "#/signup", after_login: "/register")
        spree_get :show, confirmation_token: unconfirmed_user.confirmation_token
        expect(response).
          to redirect_to registration_path(anchor: "#/signup",
                                           after_login: "/register", validation: "confirmed")
      end

      it "redirects to set password page, if user needs to reset their password" do
        unconfirmed_user.reset_password_token = Devise.friendly_token
        unconfirmed_user.save!
        spree_get :show, confirmation_token: unconfirmed_user.confirmation_token
        expect(response).to be_redirect
        expect(response.body).to include spree.edit_spree_user_password_path
      end
    end
  end

  context "requesting confirmation instructions to be resent" do
    it "redirects the user to login" do
      spree_post :create, spree_user: { email: unconfirmed_user.email }
      expect(response).to redirect_to login_path
      expect(flash[:success]).to eq 'Email confirmation sent'
    end

    it "sends the confirmation email" do
      expect do
        spree_post :create, spree_user: { email: unconfirmed_user.email }
      end.to enqueue_job ActionMailer::MailDeliveryJob

      expect(enqueued_jobs.last.to_s).to match "confirmation_instructions"
    end
  end
end
