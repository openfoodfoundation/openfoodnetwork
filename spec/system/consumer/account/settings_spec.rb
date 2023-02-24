# frozen_string_literal: true

require 'system_helper'

describe "Account Settings" do
  include AuthenticationHelper
  include OpenFoodNetwork::EmailHelper

  describe "as a logged in user" do
    let(:user) do
      create(:user,
             email: 'old@email.com',
             password: 'OriginalPassword',
             password_confirmation: 'OriginalPassword')
    end

    before do
      setup_email
      login_as user
      visit "/account"
      find("a", text: /Account Settings/i).click
      expect(page).to have_content 'Account Settings'
    end

    it "allows the user to update their email address" do
      fill_in 'user_email', with: 'new@email.com'

      performing_deliveries do
        expect do
          click_button 'Update'
        end.to enqueue_job ActionMailer::MailDeliveryJob
      end

      expect(enqueued_jobs.last.to_s).to match "new@email.com"

      expect(find(".alert-box.success").text.strip).to eq "Account updated!\n×"
      user.reload
      expect(user.email).to eq 'old@email.com'
      expect(user.unconfirmed_email).to eq 'new@email.com'
      find("a", text: /Account Settings/i).click
      expect(page).to have_content "Pending email confirmation for: %s. \
Your email address will be updated once the new email is confirmed." % 'new@email.com'
    end

    it "allows the user to change their password" do
      initial_password = user.encrypted_password

      fill_in 'user_password', with: 'NewPassword'
      fill_in 'user_password_confirmation', with: 'NewPassword'

      click_button 'Update'
      expect(find(".alert-box.success").text.strip).to eq "Account updated!\n×"

      expect(user.reload.encrypted_password).to_not eq initial_password
    end
  end
end
