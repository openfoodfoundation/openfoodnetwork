# frozen_string_literal: true

require "system_helper"

describe "Mail Methods" do
  include AuthenticationHelper

  before { login_as_admin_and_visit spree.edit_admin_general_settings_path }

  context "edit" do
    before { click_link "Mail Method Settings" }

    it "only allows changing the mails_from setting" do
      fill_in 'mails_from', with: 'ofn@example.com'
      fill_in 'mail_bcc', with: 'bcc@example.com'
      expect(page).to have_field('intercept_email', disabled: true)

      click_button 'Update'
      expect(page).to have_content('successfully updated!')
    end
  end
end
