# frozen_string_literal: true

require "system_helper"

describe "Visit Admin", js: true do
  include UIComponentHelper
  include AuthenticationHelper
  include WebHelper
  let(:user) { create(:user, password: "password", password_confirmation: "password") }
  let!(:enterprise) { create(:enterprise, owner: user) } # Required for access to admin

  scenario "logging into admin redirects home, then back to admin" do
    visit spree.admin_dashboard_path

    fill_in "Email", with: user.email
    fill_in "Password", with: user.password

    click_login_button
    expect(page).to have_content "DASHBOARD"
    expect(page).to have_current_path spree.admin_dashboard_path
    expect(page).to have_no_content "CONFIGURATION"
  end
end
