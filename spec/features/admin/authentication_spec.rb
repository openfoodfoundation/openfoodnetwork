require 'spec_helper'

feature "Authentication", js: true do
  include UIComponentHelper
  include AuthenticationWorkflow
  include WebHelper

  let(:user) { create(:user, password: "password", password_confirmation: "password") }
  let!(:enterprise) { create(:enterprise, owner: user) } # Required for access to admin

  scenario "logging into admin redirects home, then back to admin" do
    # This is the first admin spec, so give a little extra load time for slow systems
    Capybara.using_wait_time(120) do
      visit spree.admin_path

      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
      click_login_button
      expect(page).to have_content "DASHBOARD"
      expect(page).to have_current_path spree.admin_path
      expect(page).to have_no_content "CONFIGURATION"
    end
  end

  scenario "viewing my account" do
    login_to_admin_section
    click_link "Account"
    expect(page).to have_current_path spree.account_path
  end
end
