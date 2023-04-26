# frozen_string_literal: true

require 'system_helper'

describe "Mail Methods" do
  include AuthenticationHelper

  before do
    login_as_admin
    visit spree.edit_admin_general_settings_path
  end

  context "edit" do
    before { click_link "Mail Method Settings" }

    it "only allows changing the mails_from setting" do
      fill_in 'mails_from', with: 'ofn@example.com'
      fill_in 'mail_bcc', with: 'bcc@example.com'

      click_button 'Update'
      expect(page).to have_content('successfully updated!')
    end
  end
end
