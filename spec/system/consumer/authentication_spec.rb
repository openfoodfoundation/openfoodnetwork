# frozen_string_literal: true

require 'system_helper'

describe "Authentication" do
  include AuthenticationHelper
  include UIComponentHelper
  include OpenFoodNetwork::EmailHelper

  describe "login" do
    let(:user) { create(:user, password: "password", password_confirmation: "password") }

    describe "With redirects" do
      it "logging in with a redirect set" do
        visit groups_path(anchor: "/login", after_login: producers_path)
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

        describe "logging in" do
          it "showing login" do
            expect(page).to have_login_modal
          end

          it "failing to login" do
            fill_in "Email", with: user.email
            click_login_button
            expect(page).to have_content "Invalid email or password"
          end

          it "logging in successfully" do
            fill_in "Email", with: user.email
            fill_in "Password", with: user.password
            click_login_button
            expect(page).to be_logged_in_as user
          end

          context "using keyboard" do
            it "logging in successfully" do
              fill_in_using_keyboard
              expect(page).to be_logged_in_as user
            end
          end

          context "with an unconfirmed email" do
            let!(:user) {
              Spree::User.create(email: "test@example.com", unconfirmed_email: "test@example.com", password: "password")
            }

            it "shows an error and an option to resend the confirmation email" do
              fill_in "Email", with: user.email
              fill_in "Password", with: user.password
              click_login_button

              expect(page).to have_content 'You must confirm your email address before you can reset your password.'
              expect do
                page.find("a", text: 'Resend confirmation email.').click
              end.to enqueue_job ActionMailer::MailDeliveryJob
              expect(enqueued_jobs.last.to_s).to match "confirmation_instructions"

              expect(page).to have_content 'You will receive an email with instructions about how to confirm your account in a few minutes.'

              visit spree.spree_user_confirmation_path(confirmation_token: user.confirmation_token)
              expect(user.reload.confirmed?).to be true
              expect(page).to have_text 'Thanks for confirming your email! You can now log in.'
            end
          end
        end

        describe "signing up" do
          before do
            select_login_tab "Sign up"
          end

          it "Failing to sign up because password is too short" do
            fill_in "Your email", with: "test@foo.com"
            fill_in "Choose a password", with: "short"
            click_signup_button
            expect(page).to have_content "too short"
          end

          it "Failing to sign up because email is already registered" do
            fill_in "Your email", with: user.email
            fill_in "Choose a password", with: "foobarino"
            click_signup_button
            expect(page).to have_content "There's already an account for this email."
          end

          it "Failing to sign up because password confirmation doesn't match or is blank" do
            fill_in "Your email", with: user.email
            fill_in "Choose a password", with: "ForgotToRetype"
            click_signup_button
            expect(page).to have_content "doesn't match"
          end

          it "Signing up successfully" do
            fill_in "Your email", with: "test@foo.com"
            fill_in "Choose a password", with: "test12345"
            fill_in "Confirm password", with: "test12345"

            expect do
              click_signup_button
              expect(page).to have_content 'A message with a confirmation link has been sent to your email address. Please open the link to activate your account.'
            end.to enqueue_job ActionMailer::MailDeliveryJob
          end
        end

        describe "forgetting passwords" do
          before do
            ActionMailer::Base.deliveries.clear
            select_login_tab "Forgot Password?"
          end

          it "failing to reset password" do
            fill_in "Your email", with: "notanemail@myemail.com"
            click_reset_password_button
            expect(page).to have_content "Email address not found"
          end

          it "resetting password" do
            fill_in "Your email", with: user.email
            expect do
              click_reset_password_button
              expect(page).to have_reset_password
            end.to enqueue_job ActionMailer::MailDeliveryJob

            expect(enqueued_jobs.last.to_s).to match "reset_password_instructions"
          end

          context "user with unconfirmed email" do
            let(:email) { "test@example.org" }
            let!(:user) {
              Spree::User.create(email: email, unconfirmed_email: email, password: "secret")
            }

            it "cannot reset password before confirming email" do
              fill_in "Your email", with: email
              click_reset_password_button
              expect(page).to have_content 'You must confirm your email address before you can reset your password.'
              page.find("a", text: 'Resend confirmation email.').click
              expect(page).to have_content 'You will receive an email with instructions about how to confirm your account in a few minutes.'

              visit spree.spree_user_confirmation_path(confirmation_token: user.confirmation_token)
              expect(user.reload.confirmed?).to be true
              expect(page).to have_text 'Thanks for confirming your email! You can now log in.'

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
        it "showing login" do
          open_off_canvas
          open_login_modal
          expect(page).to have_login_modal
        end
      end
    end

    describe "Logging in from the private shop page" do
      let(:distributor) { create(:distributor_enterprise, require_login: true) }
      let!(:order_cycle) {
        create(:simple_order_cycle, distributors: [distributor],
                                    coordinator: create(:distributor_enterprise))
      }
      before do
        visit enterprise_shop_path(distributor)
      end

      it "clicking login triggers the login modal" do
        within "#shop-tabs" do
          find("a", text: "login").click
        end
        expect(page).to have_selector("a.active", text: "Login")
        expect(page).to have_button("Login")
      end
    end

    describe "after following email confirmation link" do
      it "shows confirmed message in modal" do
        visit root_path(anchor: "/login", validation: "confirmed")
        expect(page).to have_login_modal
        expect(page).to have_content 'Thanks for confirming your email! You can now log in.'
      end
    end

    it "Loggin by typing login/ redirects to /#/login" do
      visit "/login"
      uri = URI.parse(current_url)
      expect("#{uri.path}##{uri.fragment}").to eq('/#/login')
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

          expect(page).to have_content 'COMPRAR AHORA'
        end
      end

      context "when the user has an unavailable locale saved" do
        before do
          user.update!(locale: "xx")
        end

        it "logs in successfully and resets the user's locale to the default" do
          fill_in_and_submit_login_form(user)
          expect_logged_in

          expect(page).to have_content 'SHOP NOW'
          expect(user.reload.locale).to eq "en"
        end
      end

      context "when the user has never selected a locale, but one has been selected before login" do
        before do
          user.update!(locale: nil)
        end

        it "logs in successfully and uses the locale from cookies" do
          page.driver.set_cookie("locale", "es")

          fill_in_and_submit_login_form(user)
          expect_logged_in

          expect(page).to have_content 'COMPRAR AHORA'
          expect(user.reload.locale).to eq "es"

          page.driver.remove_cookie("locale")
        end
      end
    end
  end
end
