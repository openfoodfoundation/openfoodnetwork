# frozen_string_literal: true

module AuthenticationHelper
  include Warden::Test::Helpers

  def login_as_admin
    admin_user = create(:admin_user)
    login_as admin_user
    admin_user
  end

  def login_as_admin_and_visit(path_visit)
    login_as_admin
    visit path_visit
  end

  def login_to_admin_section
    login_as_admin_and_visit(spree.admin_dashboard_path)
  end

  def login_to_admin_as(user)
    login_as user
    visit spree.admin_dashboard_path
  end

  def fill_in_and_submit_login_form(user)
    fill_in "email", with: user.email
    fill_in "password", with: user.password
    click_button "Login"
  end

  def expect_logged_in
    # Ensure page has been reloaded after submitting login form
    expect(page).to_not have_selector ".menu #login-link"
  end
end
