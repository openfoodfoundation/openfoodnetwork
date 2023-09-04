# frozen_string_literal: true

module AuthenticationHelper
  include Warden::Test::Helpers

  def login_as_admin
    login_as create(:admin_user)
  end

  def login_to_admin_section
    login_as_admin
    visit spree.admin_dashboard_path
  end

  def fill_in_and_submit_login_form(user)
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Login"
  end

  def expect_logged_in
    # Ensure page has been reloaded after submitting login form
    expect(page).to_not have_selector ".menu #login-link"
    expect(page).to_not have_content "Login"
  end
end
