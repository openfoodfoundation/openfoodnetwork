# frozen_string_literal: false

RSpec.describe Spree::UserSessionsController do
  let(:user) { create(:user) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
  end

  describe "create" do
    context "success" do
      context "when referer is not '/checkout'" do
        it "redirects to root" do
          spree_post :create, spree_user: { email: user.email, password: user.password }

          expect(response).to have_http_status(:found)
          expect(response.location).to eq root_url
        end
      end

      context "when referer is '/checkout'" do
        before { @request.env['HTTP_REFERER'] = 'http://test.com/checkout' }

        it "redirects to checkout" do
          spree_post :create, spree_user: { email: user.email, password: user.password }

          expect(response).to have_http_status(:found)
          expect(response.location).to eq checkout_url
        end
      end
    end

    context "failing to log in" do
      render_views

      it "returns an error" do
        spree_post :create, spree_user: { email: user.email, password: "wrong" },
                            format: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
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
