# frozen_string_literal: true

RSpec.describe "OAuth provider feature toggle" do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application) }

  context "when disabled" do
    it "doesn't expose the OAuth endpoints" do
      sign_in user

      get "/oauth/authorize", params: { client_id: application.uid, response_type: "code" }
      expect(response).to have_http_status :not_found

      post "/oauth/token", params: { grant_type: "authorization_code" }
      expect(response).to have_http_status :not_found

      get "/oauth/userinfo"
      expect(response).to have_http_status :not_found

      delete "/account/connected_apps/#{application.id}"
      expect(response).to have_http_status :not_found
    end

    it "doesn't show the user's Connected Apps tab" do
      sign_in user

      get spree.account_path

      expect(response.body).not_to include "account/connected_apps.html"
    end

    it "hides the admin pages" do
      sign_in create(:admin_user)

      get "/admin/oauth_applications"
      expect(response).to have_http_status :not_found

      get "/admin/oauth_tokens"
      expect(response).to have_http_status :not_found

      get spree.edit_admin_general_settings_path
      expect(response.body).not_to include "/admin/oauth_applications"
      expect(response.body).not_to include "/admin/oauth_tokens"
    end
  end

  context "when enabled", feature: :oauth_provider do
    it "exposes the OAuth endpoints" do
      get "/oauth/userinfo"

      expect(response).to have_http_status :unauthorized
    end
  end
end
