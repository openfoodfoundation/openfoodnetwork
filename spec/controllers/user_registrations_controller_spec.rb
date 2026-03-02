# frozen_string_literal: true

RSpec.describe UserRegistrationsController do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
  end

  describe "create" do
    render_views

    let(:user_params) do
      {
        email: "test@test.com",
        password: "testy123",
        password_confirmation: "testy123"
      }
    end

    it "returns validation errors" do
      post :create, params: { spree_user: {}, use_route: :spree }, as: :json
      expect(response).to have_http_status(:unauthorized)
      json = response.parsed_body
      expect(json).to eq("email" => ["can't be blank"], "password" => ["can't be blank"])
    end

    it "returns error when emailing fails" do
      allow(Spree::UserMailer).to receive(:confirmation_instructions).and_raise("Some error")
      expect(Alert).to receive(:raise)

      post :create, params: { spree_user: user_params, use_route: :spree }, as: :json

      expect(response).to have_http_status(:unauthorized)
      json = response.parsed_body
      expect(json).to eq(
        "message" =>
        'Something went wrong while creating your account. Check your email address and try again.'
      )
    end

    it "returns 200 when registration succeeds" do
      post :create, params: { spree_user: user_params, use_route: :spree }, as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to eq("email" => "test@test.com")
      expect(controller.spree_current_user).to be_nil
    end

    it "sets user.locale from cookie on create" do
      cookies[:locale] = "pt"
      post :create, params: { spree_user: user_params, use_route: :spree }, as: :json
      expect(assigns[:user].locale).to eq("pt")
    end
  end
end
