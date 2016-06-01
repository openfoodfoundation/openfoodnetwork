require 'spec_helper'

feature "Authentication", js: true, retry: 3 do
  include UIComponentHelper

  # Attempt to address intermittent failures in these specs
  around do |example|
    Capybara.using_wait_time(120) { example.run }
  end

  describe "login" do
    let(:user) { create(:user, password: "password", password_confirmation: "password") }

    describe "With redirects" do
      scenario "logging in with a redirect set" do
        visit groups_path(anchor: "login?after_login=#{producers_path}")
        fill_in "Email", with: user.email
        fill_in "Password", with: user.password
        click_login_button
        page.should have_content "Find local producers"
        expect(page).to have_current_path producers_path
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
            expect do
              click_signup_button
              page.should have_content "Welcome! You have signed up successfully"
            end.to enqueue_job ConfirmSignupJob
            page.should be_logged_in_as "test@foo.com"
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
            expect do
              click_reset_password_button
              page.should have_reset_password
            end.to enqueue_job Delayed::PerformableMethod
            Delayed::Job.last.payload_object.method_name.should == :send_reset_password_instructions_without_delay
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

    scenario "Loggin by typing login/ redirects to /#/login" do
      visit "/login"
      uri = URI.parse(current_url)
      (uri.path + "#" + uri.fragment).should == '/#/login'
    end
  end
end
