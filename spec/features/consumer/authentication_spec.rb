require 'spec_helper'

feature "Authentication", js: true do
  include AuthenticationHelper
  include UIComponentHelper
  include OpenFoodNetwork::EmailHelper

  describe "login" do
    let(:user) { create(:user, password: "password", password_confirmation: "password") }

    describe "With redirects" do
      scenario "logging in with a redirect set" do
        visit groups_path(anchor: "login?after_login=#{producers_path}")
        fill_in "Email", with: user.email
        fill_in "Password", with: user.password
        click_login_button
        expect(page).to have_content "Find local producers"
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
          expect(page).to have_login_modal
        end

        scenario "failing to login" do
          fill_in "Email", with: user.email
          click_login_button
          expect(page).to have_content "Invalid email or password"
        end

        scenario "logging in successfully" do
          fill_in "Email", with: user.email
          fill_in "Password", with: user.password
          click_login_button
          expect(page).to be_logged_in_as user
        end

        describe "signing up" do
          before do
            select_login_tab "Sign up"
          end

          scenario "Failing to sign up because password is too short" do
            fill_in "Email", with: "test@foo.com"
            fill_in "Choose a password", with: "short"
            click_signup_button
            expect(page).to have_content "too short"
          end

          scenario "Failing to sign up because email is already registered" do
            fill_in "Email", with: user.email
            fill_in "Choose a password", with: "foobarino"
            click_signup_button
            expect(page).to have_content "There's already an account for this email."
          end

          scenario "Failing to sign up because password confirmation doesn't match or is blank" do
            fill_in "Email", with: user.email
            fill_in "Choose a password", with: "ForgotToRetype"
            click_signup_button
            expect(page).to have_content "doesn't match"
          end

          scenario "Signing up successfully" do
            performing_deliveries do
              setup_email
              fill_in "Email", with: "test@foo.com"
              fill_in "Choose a password", with: "test12345"
              fill_in "Confirm password", with: "test12345"

              expect do
                click_signup_button
                expect(page).to have_content I18n.t('devise.user_registrations.spree_user.signed_up_but_unconfirmed')
              end.to enqueue_job ActionMailer::DeliveryJob
            end
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
            expect(page).to have_content "Email address not found"
          end

          scenario "resetting password" do
            fill_in "Your email", with: user.email
            expect do
              click_reset_password_button
              expect(page).to have_reset_password
            end.to enqueue_job ActionMailer::DeliveryJob
          end

          context "user with unconfirmed email" do
            let(:email) { "test@example.org" }
            let!(:user) { Spree::User.create(email: email, unconfirmed_email: email, password: "secret") }

            scenario "cannot reset password before confirming email" do
              fill_in "Your email", with: email
              click_reset_password_button
              expect(page).to have_content I18n.t('email_unconfirmed')
              page.find("a", text: I18n.t('devise.confirmations.resend_confirmation_email')).click
              expect(page).to have_content I18n.t('devise.confirmations.send_instructions')

              visit spree.spree_user_confirmation_path(confirmation_token: user.confirmation_token)
              expect(user.reload.confirmed?).to be true
              expect(page).to have_text I18n.t('devise.confirmations.confirmed')

              select_login_tab "Forgot Password?"
              fill_in "Your email", with: email
              click_reset_password_button
              expect(page).to have_reset_password
            end
          end
        end
      end

      describe "as medium" do
        before do
          browse_as_medium
        end
        after do
          browse_as_large
        end
        scenario "showing login" do
          open_off_canvas
          open_login_modal
          expect(page).to have_login_modal
        end
      end
    end

    describe "after following email confirmation link" do
      scenario "shows confirmed message in modal" do
        visit '/#/login?validation=confirmed'
        expect(page).to have_login_modal
        expect(page).to have_content I18n.t('devise.confirmations.confirmed')
      end
    end

    scenario "Loggin by typing login/ redirects to /#/login" do
      visit "/login"
      uri = URI.parse(current_url)
      expect(uri.path + "#" + uri.fragment).to eq('/#/login')
    end

    describe "with user locales" do
      before do
        visit root_path
        open_login_modal
      end

      context "when the user has a valid locale saved" do
        before do
          user.update!(locale: "es")
        end

        it "logs in successfully, applying the saved locale" do
          fill_in_and_submit_login_form(user)
          expect_logged_in

          expect(page).to have_content I18n.t(:home_shop, locale: :es).upcase
        end
      end

      context "when the user has an unavailable locale saved" do
        before do
          user.update!(locale: "xx")
        end

        it "logs in successfully and resets the user's locale to the default" do
          fill_in_and_submit_login_form(user)
          expect_logged_in

          expect(page).to have_content I18n.t(:home_shop, locale: :en).upcase
          expect(user.reload.locale).to eq "en"
        end
      end

      context "when the user has never selected a locale, but one has been selected before login" do
        before do
          user.update!(locale: nil)
        end

        it "logs in successfully and uses the locale from cookies" do
          page.driver.browser.manage.add_cookie(name: 'locale', value: 'es')

          fill_in_and_submit_login_form(user)
          expect_logged_in

          expect(page).to have_content I18n.t(:home_shop, locale: :es).upcase
          expect(user.reload.locale).to eq "es"

          page.driver.browser.manage.delete_cookie('locale')
        end
      end
    end
  end
end
