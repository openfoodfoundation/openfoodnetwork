require 'spec_helper'

feature "Authentication", js: true do
  describe "login" do
    let(:user) { create(:user, password: "password", password_confirmation: "password") }
    scenario "with valid credentials" do
      visit "/login"
      fill_in "Email", with: user.email
      fill_in "Password", with: "password"
      click_button "Login"
      current_path.should == "/"
    end

    scenario "with invalid credentials" do
      visit "/login"
      fill_in "Email", with: user.email
      fill_in "Password", with: "this isn't my password"
      click_button "Login"
      page.should have_content "Invalid email or password"
    end
  end
end

