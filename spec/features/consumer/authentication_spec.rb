require 'spec_helper'

feature "Authentication", js: true do
  include UIComponentHelper
  describe "login" do
    let(:user) { create(:user, password: "password", password_confirmation: "password") }

    describe "newskool" do
      before do
        visit root_path
      end
      describe "as large" do
        before do
          browse_as_large
        end
        scenario "showing login" do
          open_login_modal
          page.should have_login_modal
        end
      end
      describe "as medium" do
        before do
          browse_as_medium
        end
        scenario "showing login" do
          open_off_canvas 
          binding.pry
          open_login_modal
          save_screenshot "/Users/willmarshall/Desktop/modal.png", :full => true
          page.should have_login_modal
        end
      end
    end

    describe "oldskool" do
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
end

