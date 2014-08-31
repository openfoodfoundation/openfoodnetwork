require 'spec_helper'

feature "Authentication", js: true do
  include UIComponentHelper
  let(:user) { create(:user, password: "password", password_confirmation: "password") }

  scenario "logging into admin redirects home, then back to admin" do
    visit spree.admin_path
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_login_button
    page.should have_content "Dashboard"
    current_path.should == spree.admin_path
  end
end
