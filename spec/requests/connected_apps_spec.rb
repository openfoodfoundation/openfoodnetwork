# frozen_string_literal: true

RSpec.describe "Connected apps", feature: :oauth_provider do
  let(:user) { create(:user) }
  let(:application) {
    create(:oauth_application, name: "Delivery planner",
                               redirect_uri: "https://planner.example.com/callback")
  }
  let!(:token) { Doorkeeper::AccessToken.create!(application:, resource_owner_id: user.id) }

  context "when logged in" do
    before { sign_in user }

    it "lists the applications the user authorized in an account tab" do
      other_app = create(:oauth_application, name: "Stock sync")
      Doorkeeper::AccessToken.create!(application: other_app, resource_owner_id: create(:user).id)

      get spree.account_path

      expect(response.body).to include 'id="account/connected_apps.html"'
      expect(response.body).to include "Delivery planner", "planner.example.com"
      expect(response.body).to include spree.account_connected_app_path(application)
      expect(response.body).not_to include "Stock sync"
    end

    it "revokes an application and goes back to the tab" do
      delete spree.account_connected_app_path(application)

      expect(response).to redirect_to "#{spree.account_path}#/connected_apps"
      expect(flash[:success]).to eq "Delivery planner can no longer access your account."
      expect(token.reload).to be_revoked
    end

    it "doesn't revoke another user's tokens" do
      other_token = Doorkeeper::AccessToken.create!(application:,
                                                    resource_owner_id: create(:user).id)

      delete spree.account_connected_app_path(application)

      expect(other_token.reload).not_to be_revoked
    end
  end

  it "asks a guest to log in" do
    delete spree.account_connected_app_path(application)

    expect(response).to have_http_status :redirect
    expect(token.reload).not_to be_revoked
  end
end
