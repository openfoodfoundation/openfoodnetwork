require 'spec_helper'

feature "Authentication", js: true do
  include UIComponentHelper
  describe "login" do
    let(:user) { create(:user, password: "password", password_confirmation: "password") }

    describe "With redirects" do
      scenario "logging in with a redirect set" do
        visit groups_path(anchor: "login?after_login=#{producers_path}")
        fill_in "Email", with: user.email
        fill_in "Password", with: user.password
        click_login_button
        page.should have_content "Find local producers"
        current_path.should == producers_path
      end
    end

    describe "Loggin in from the home page" do
      before do
        visit root_path
      end
      describe "as large" do
        before do
          browse_as_large
          open_login_modal
        end
        scenario "showing login" do
          page.should have_login_modal
        end

        scenario "failing to login" do
          fill_in "Email", with: user.email
          click_login_button
          page.should have_content "Invalid email or password"    
        end

        scenario "logging in successfully" do
          fill_in "Email", with: user.email
          fill_in "Password", with: user.password
          click_login_button
          page.should be_logged_in_as user
        end

        describe "signing up" do
          before do
            ActionMailer::Base.deliveries.clear
            select_login_tab "Sign up"
          end
          scenario "Failing to sign up because password is too short" do
            fill_in "Email", with: "test@foo.com"
            fill_in "Choose a password", with: "short"
            click_signup_button
            page.should have_content "too short"
          end

          scenario "Signing up successfully" do
            fill_in "Email", with: "test@foo.com"
            fill_in "Choose a password", with: "test12345"
            fill_in "Confirm password", with: "test12345"
            click_signup_button
            page.should have_content "Welcome! You have signed up successfully"
            page.should be_logged_in_as "test@foo.com"
            ActionMailer::Base.deliveries.last.subject.should =~ /Welcome to/
          end
        end

        describe "forgetting passwords" do
          before do
            ActionMailer::Base.deliveries.clear
            select_login_tab "Forgot Password?"
          end
          
          scenario "failing to reset password" do
            fill_in "Your email", with: "notanemail@myemail.com"
            click_reset_password_button
            page.should have_content "Email address not found"
          end

          scenario "resetting password" do
            fill_in "Your email", with: user.email 
            click_reset_password_button
            page.should have_reset_password
            ActionMailer::Base.deliveries.last.subject.should =~ /Password Reset/
          end
        end
      end
      describe "as medium" do
        before do
          browse_as_medium
        end
        scenario "showing login" do
          open_off_canvas 
          open_login_modal
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

