# frozen_string_literal: true

RSpec.describe UserPasswordsController do
  render_views

  let(:user) { create(:user) }
  let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
  end

  describe "create" do
    # The response must not tell whether an account exists for the email
    shared_examples "a neutral response" do
      it "returns the same response" do
        request_reset
        expect(response).to have_http_status :ok
        expect(response.body).to match "If an account with that email address exists, \
you will receive a password reset email"
        expect(response.body).to include 'class="alert-box success"'
        expect(response.body).not_to match "Resend confirmation email"
      end
    end

    let(:request_reset) {
      spree_post :create, spree_user: { email: }, format: :turbo_stream
    }

    context "when no account has the email" do
      let(:email) { "xxxxxxxxxx@example.com" }

      it_behaves_like "a neutral response"

      it "doesn't send an email" do
        expect { request_reset }.not_to enqueue_job ActionMailer::MailDeliveryJob
      end
    end

    context "when the email is blank" do
      let(:email) { "" }

      it_behaves_like "a neutral response"

      it "doesn't send an email" do
        expect { request_reset }.not_to enqueue_job ActionMailer::MailDeliveryJob
      end
    end

    it "returns 422 if user is registered but not confirmed" do
      spree_post :create, spree_user: { email: unconfirmed_user.email }, format: :turbo_stream
      expect(response).to have_http_status :unprocessable_entity
      expect(response.body).to match "You must confirm your email \
address before you can reset your password."
    end

    it "returns 200 when password reset was successful" do
      spree_post :create, spree_user: { email: user.email }, format: :turbo_stream
      expect(response).to have_http_status :ok
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
