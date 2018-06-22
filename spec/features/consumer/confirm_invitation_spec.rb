require "spec_helper"

feature "Confirm invitation as manager" do
  include UIComponentHelper # for be_logged_in_as

  describe "confirm email and set password" do
    let(:email) { "test@example.org" }
    let(:user) { Spree::User.create(email: email, unconfirmed_email: email, password: "secret") }

    before do
      user.reset_password_token = Devise.friendly_token
      user.reset_password_sent_at = Time.now.utc
      user.save!
    end

    it "allows you to set a password" do
      visit spree.spree_user_confirmation_url(confirmation_token: user.confirmation_token)

      expect(user.reload.confirmed?).to be true
      expect(page).to have_text "Change my password"

      fill_in "Password", with: "my secret"
      fill_in "Password Confirmation", with: "my secret"
      click_button

      expect(page).to have_no_text "Reset password token has expired"
      expect(page).to be_logged_in_as user
    end
  end
end
