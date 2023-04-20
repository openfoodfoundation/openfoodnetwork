# frozen_string_literal: true

require "system_helper"

describe "User password confirm/reset page" do
  include UIComponentHelper

  let(:email) { "test@example.org" }
  let(:user) { Spree::User.create(email: email, unconfirmed_email: email, password: "secret") }

  describe "can set a password" do
    before do
      user.reset_password_token = Devise.friendly_token
      user.reset_password_sent_at = Time.now.utc
      user.save!
    end

    it "lets the user set a password" do
      visit spree.spree_user_confirmation_path(confirmation_token: user.confirmation_token)

      expect(user.reload.confirmed?).to be true
      expect(page).to have_text 'Change my password'

      fill_in "Password", with: "my secret"
      fill_in "Password Confirmation", with: "my secret"
      click_button

      expect(page).to have_no_text "Reset password token has expired"
      expect(page).to be_logged_in_as user
    end

    it "shows an error if password is empty" do
      visit spree.spree_user_confirmation_path(confirmation_token: user.confirmation_token)

      expect(user.reload.confirmed?).to be true
      expect(page).to have_text 'Change my password'

      fill_in "Password", with: ""
      fill_in "Password Confirmation", with: ""
      click_button

      expect(page).to have_text "User password cannot be blank. Please enter a password."
      expect(page).to_not be_logged_in_as user
    end
  end

  describe "can reset its own password" do
    let(:reset_password_token) { user.regenerate_reset_password_token }

    it "has the right error when password aren't the same" do
      visit spree.edit_spree_user_password_path(reset_password_token: reset_password_token)

      expect(page).to have_text "Change my password"

      fill_in "Password", with: "my secret"
      fill_in "Password Confirmation", with: "my secret1"
      click_button

      expect(page).to have_text "Password confirmation doesn't match Password"
    end

    it "has the right error message whend reset token is invalid" do
      visit spree.edit_spree_user_password_path(reset_password_token: "#{reset_password_token}-i")

      fill_in "Password", with: "my secret"
      fill_in "Password Confirmation", with: "my secret"
      click_button

      expect(page).to have_text "Reset password token is invalid"
    end

    it "has the right error message whend reset token is invalid" do
      reset_password_token = user.regenerate_reset_password_token
      user.reset_password_sent_at = 2.days.ago
      user.save!

      visit spree.edit_spree_user_password_path(reset_password_token: reset_password_token)

      fill_in "Password", with: "my secret"
      fill_in "Password Confirmation", with: "my secret"
      click_button

      expect(page).to have_text "Reset password token has expired, please request a new one"
    end

    it "can actually reset its own password" do
      visit spree.edit_spree_user_password_path(reset_password_token: reset_password_token)

      fill_in "Password", with: "my secret"
      fill_in "Password Confirmation", with: "my secret"
      click_button

      expect(page).to have_text "Your password has been changed successfully"
    end
  end
end
