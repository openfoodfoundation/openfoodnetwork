# frozen_string_literal: true

require 'spec_helper'

describe UserPasswordsController, type: :controller do
  include OpenFoodNetwork::EmailHelper

  let(:user) { create(:user) }
  let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
  end

  describe "create" do
    it "returns errors" do
      spree_post :create, spree_user: {}
      expect(response.status).to eq 200
      expect(response).to render_template "spree/user_passwords/new"
    end

    it "redirects to login when data is valid" do
      spree_post :create, spree_user: { email: user.email }
      expect(response).to be_redirect
    end
  end

  describe "edit" do
    context "when given a redirect" do
      it "stores the redirect path in 'spree_user_return_to'" do
        spree_post :edit, reset_password_token: "token", return_to: "/return_path"
        expect(session["spree_user_return_to"]).to eq "/return_path"
      end
    end
  end

  it "renders Darkswarm" do
    setup_email
    clear_jobs

    user.send_reset_password_instructions
    flush_jobs # Send the reset password instructions

    user.reload
    spree_get :edit, reset_password_token: user.reset_password_token

    expect(response).to render_template "user_passwords/edit"
  end

  describe "via ajax" do
    it "returns error when email not found" do
      post :create, xhr: true, params: { spree_user: {}, use_route: :spree }
      expect(response.status).to eq 404
      expect(json_response).to eq 'error' => I18n.t('email_not_found')
    end

    it "returns error when user is unconfirmed" do
      post :create, xhr: true, params: { spree_user: { email: unconfirmed_user.email }, use_route: :spree }
      expect(response.status).to eq 401
      expect(json_response).to eq 'error' => I18n.t('email_unconfirmed')
    end
  end
end
