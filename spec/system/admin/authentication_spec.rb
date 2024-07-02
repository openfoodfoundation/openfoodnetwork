# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Authentication" do
  include UIComponentHelper
  include AuthenticationHelper
  include WebHelper

  let(:user) { create(:user, password: "password", password_confirmation: "password") }
  let!(:enterprise) { create(:enterprise, owner: user) } # Required for access to admin

  context "as anonymous user" do
    it "logging into admin redirects home, then back to admin" do
      visit spree.admin_dashboard_path

      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
      click_login_button
      expect(page).to have_content "Dashboard"
      expect(page).to have_current_path spree.admin_dashboard_path
      expect(page).not_to have_content "Configuration"
    end

    it "viewing my account" do
      login_to_admin_section
      click_link "Account"
      expect(page).to have_current_path spree.account_path
    end

    it "is redirected to login page when attempting to access product listing" do
      expect { visit spree.admin_products_path }.not_to raise_error
    end
  end

  context "logged in" do
    before do
      login_as user
      visit root_path
    end

    it "logs out" do
      page.find("li", class: "user-menu").click
      click_on "Logout"
      expect(page).to have_content "Signed out successfully."
      expect(page).to have_content "Login"
    end
  end
end
