# frozen_string_literal: true

require 'system_helper'

RSpec.describe "OIDC Settings" do
  it "requires login" do
    visit admin_oidc_settings_path
    expect(page).to have_button "Login"
    expect(page).not_to have_button "Link your Les Communs OIDC Account"
  end

  describe "with valid login" do
    let(:user) { create(:enterprise_user) }

    before do
      OmniAuth.config.test_mode = true
      login_as user
    end

    it "allows you to connect to an account and disconnect again" do
      visit admin_oidc_settings_path
      click_button "Link your Les Communs OIDC Account"
      expect(page).to have_content "Your account is linked"

      click_button "Disconnect"
      expect(page).to have_button "Link your Les Communs OIDC Account"
    end

    it "allows you to refresh authorisation tokens" do
      OidcAccount.create!(user:, provider: "openid_connect", uid: "a@b.com")
      OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
        JSON.parse(file_fixture("omniauth.auth.json").read)
      )

      visit admin_oidc_settings_path

      expect(page).to have_content "Tokens to access connected apps have expired"
      click_button "Refresh authorisation"
      expect(page).not_to have_content "Tokens to access connected apps have expired"
    end
  end
end
