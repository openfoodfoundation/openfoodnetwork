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
        before { @request.env['HTTP_REFERER'] = 'http://test.host/checkout' }

        it "redirects to checkout" do
          spree_post :create, spree_user: { email: user.email, password: user.password }

          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(checkout_url)
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

      context "with an unconfirmed email" do
        let(:user) { create(:user, confirmed_at: nil) }

        it "says the email is unconfirmed when the password is right" do
          spree_post :create, spree_user: { email: user.email, password: user.password },
                              format: :turbo_stream

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include "You must confirm your email address"
          expect(response.body).to include "Resend confirmation email"
        end

        it "returns the same error as for any other account when the password is wrong" do
          spree_post :create, spree_user: { email: user.email, password: "wrong" },
                              format: :turbo_stream

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include "Invalid email or password"
          expect(response.body).not_to include "You must confirm your email address"
          expect(response.body).not_to include "Resend confirmation email"
        end

        it "doesn't say the email is unconfirmed without a password" do
          spree_post :create, spree_user: { email: user.email }, format: :turbo_stream

          expect(response.body).to include "Invalid email or password"
          expect(response.body).not_to include "You must confirm your email address"
        end
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
