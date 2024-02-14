# frozen_string_literal: true

require 'system_helper'

describe "OIDC Settings" do
  it "requires login" do
    visit admin_oidc_settings_path
    expect(page).to have_button "Login"
    expect(page).to_not have_button "Link your Les Communs OIDC Account"
  end

  describe "with valid login" do
    let(:user) { create(:admin_user) }

    before do
      OmniAuth.config.test_mode = true
      login_as user
    end

    it "allows you to connect to an account" do
      visit admin_oidc_settings_path
      click_button "Link your Les Communs OIDC Account"
      expect(page).to have_content "Your account is already linked"
    end
  end
end
