require 'spec_helper'

feature "Account Settings", js: true do
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
      click_link I18n.t('spree.users.show.tabs.settings')
      expect(page).to have_content I18n.t('spree.users.form.account_settings')
    end

    it "allows the user to update their email address" do
      fill_in 'user_email', with: 'new@email.com'

      performing_deliveries do
        expect do
          click_button I18n.t(:update)
        end.to enqueue_job ActionMailer::DeliveryJob
      end

      expect(enqueued_jobs.last.to_s).to match "new@email.com"

      expect(find(".alert-box.success").text.strip).to eq "#{I18n.t('spree.account_updated')} ×"
      user.reload
      expect(user.email).to eq 'old@email.com'
      expect(user.unconfirmed_email).to eq 'new@email.com'
      click_link I18n.t('spree.users.show.tabs.settings')
      expect(page).to have_content I18n.t('spree.users.show.unconfirmed_email', unconfirmed_email: 'new@email.com')
    end

    it "allows the user to change their password" do
      initial_password = user.encrypted_password

      fill_in 'user_password', with: 'NewPassword'
      fill_in 'user_password_confirmation', with: 'NewPassword'

      click_button I18n.t(:update)
      expect(find(".alert-box.success").text.strip).to eq "#{I18n.t('spree.account_updated')} ×"

      expect(user.reload.encrypted_password).to_not eq initial_password
    end
  end
end
