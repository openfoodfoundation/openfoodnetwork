# frozen_string_literal: true

RSpec.describe "/admin/oauth_tokens" do
  let(:admin) { create(:admin_user) }
  let(:user) { create(:user, email: "farmer@example.com") }
  let(:planner) { create(:oauth_application, name: "Delivery planner") }
  let(:sync) { create(:oauth_application, name: "Stock sync") }
  let!(:token) { Doorkeeper::AccessToken.create!(application: planner, resource_owner_id: user.id) }

  context "as a super admin" do
    before { sign_in admin }

    it "lists tokens with their user and application" do
      get admin_oauth_tokens_path

      expect(response).to have_http_status :ok
      expect(response.body).to include "farmer@example.com", "Delivery planner"
    end

    it "is linked from the configuration menu" do
      get admin_oauth_applications_path

      expect(response.body).to include admin_oauth_tokens_path
    end

    it "hides revoked tokens unless asked" do
      Doorkeeper::AccessToken.create!(application: sync, resource_owner_id: user.id).revoke

      get admin_oauth_tokens_path
      expect(response.body).not_to include "Stock sync</td>"

      get admin_oauth_tokens_path(revoked: "1")
      expect(response.body).to include "Stock sync</td>"
    end

    it "filters by application" do
      Doorkeeper::AccessToken.create!(application: sync, resource_owner_id: user.id)

      get admin_oauth_tokens_path(application_id: sync.id)

      expect(response.body).to include "Stock sync</td>"
      expect(response.body).not_to include "Delivery planner</td>"
    end

    it "revokes a token" do
      put revoke_admin_oauth_token_path(token)

      expect(response).to redirect_to admin_oauth_tokens_path
      expect(token.reload).to be_revoked
    end
  end

  context "as an enterprise user" do
    before { sign_in user }

    it "denies access" do
      get admin_oauth_tokens_path

      expect(response).to redirect_to unauthorized_path
    end

    it "can't revoke a token" do
      put revoke_admin_oauth_token_path(token)

      expect(token.reload).not_to be_revoked
    end
  end
end
