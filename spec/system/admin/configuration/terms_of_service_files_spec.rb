# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Terms of Service files" do
  include AuthenticationHelper

  describe "as admin" do
    let(:test_file_path) { "public/Terms-of-service.pdf" }

    before { login_as_admin }

    it "can be uploaded and deleted" do
      visit spree.edit_admin_general_settings_path
      click_link "Terms of Service"

      expect(page).to have_content "No terms of services have been uploaded yet."

      attach_file "Attachment", Rails.root.join(test_file_path)
      click_button "Create Terms of service file"

      expect(page).to have_link "Terms of Service"

      accept_alert { click_link "Delete" }

      expect(page).to have_content "No terms of services have been uploaded yet."
    end
  end
end
