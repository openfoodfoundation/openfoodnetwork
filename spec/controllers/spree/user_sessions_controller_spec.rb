# frozen_string_literal: false

require 'spec_helper'

describe Spree::UserSessionsController, type: :controller do
  let(:user) { create(:user) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
  end

  describe "create" do
    context "success" do
      context "when referer is not '/checkout'" do
        it "redirects to root" do
          spree_post :create, spree_user: { email: user.email, password: user.password }

          expect(response).to have_http_status(:ok)
          expect(response.body).to match(root_path).and match("redirect")
        end
      end

      context "when referer is '/checkout'" do
        before { @request.env['HTTP_REFERER'] = 'http://test.com/checkout' }

        it "redirects to checkout" do
          spree_post :create, spree_user: { email: user.email, password: user.password }

          expect(response).to have_http_status(:ok)
          expect(response.body).to match(checkout_path).and match("redirect")
        end
      end
    end

    context "failing to log in" do
      render_views

      it "returns an error" do
        spree_post :create, spree_user: { email: user.email, password: "wrong" }

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include "Invalid email or password"
      end
    end
  end

  describe "destroy" do
    it "redirects to root with flash message" do
      spree_post :destroy

      expect(response).to redirect_to root_path
      expect(flash[:notice]).to eq "Signed out successfully."
    end
  end
end
