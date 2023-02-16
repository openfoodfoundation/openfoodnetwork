# frozen_string_literal: true

require 'spec_helper'

describe UserPasswordsController, type: :controller do
  render_views

  let(:user) { create(:user) }
  let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
  end

  describe "create" do
    it "returns 404 if user is not found" do
      spree_post :create, spree_user: { email: "xxxxxxxxxx@example.com" }
      expect(response.status).to eq 404
      expect(response.body).to match 'Email address not found'
    end

    it "returns 422 if user is registered but not confirmed" do
      spree_post :create, spree_user: { email: unconfirmed_user.email }
      expect(response.status).to eq 422
      expect(response.body).to match "You must confirm your email \
address before you can reset your password."
    end

    it "returns 200 when password reset was successful" do
      spree_post :create, spree_user: { email: user.email }
      expect(response.status).to eq 200
      expect(response.body).to match "An email with instructions on resetting \
your password has been sent!"
    end
  end

  describe "edit" do
    context "when given a redirect" do
      it "stores the redirect path in 'spree_user_return_to'" do
        spree_post :edit, reset_password_token: "token", after_login: "/return_path"
        expect(session["spree_user_return_to"]).to eq "/return_path"
      end
    end
  end

  it "renders Darkswarm" do
    user.send_reset_password_instructions

    user.reload
    spree_get :edit, reset_password_token: user.reset_password_token

    expect(response).to render_template "user_passwords/edit"
  end
end
