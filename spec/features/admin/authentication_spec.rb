require 'spec_helper'

feature "Authentication", js: true do
  include UIComponentHelper
  let(:user) { create(:user, password: "password", password_confirmation: "password") }

  scenario "logging into admin redirects home, then back to admin" do
    # This is the first admin spec, so give a little extra load time for slow systems
    Capybara.using_wait_time(60) do
      visit spree.admin_path
    end

    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_login_button
    page.should have_content "Dashboard"
    current_path.should == spree.admin_path
  end
end
