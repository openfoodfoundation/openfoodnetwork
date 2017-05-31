require 'spec_helper'

feature "Account Settings", js: true do
  include AuthenticationWorkflow

  describe "as a logged in user" do
    let(:user) { create(:user) }

    before do
      quick_login_as user
    end

    it "allows me to update my account details" do
      visit "/account"

      click_link I18n.t('spree.users.show.tabs.settings')
      expect(page).to have_content I18n.t('spree.users.form.account_settings')
      fill_in 'user_email', with: 'new@email.com'

      click_button I18n.t(:update)

      expect(find(".alert-box.success").text.strip).to eq "#{I18n.t(:account_updated)} ×"
      user.reload
      expect(user.email).to eq 'new@email.com'
    end
  end
end
