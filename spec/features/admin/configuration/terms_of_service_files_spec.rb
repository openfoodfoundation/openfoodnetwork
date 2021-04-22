# frozen_string_literal: true

require 'spec_helper'

describe "Terms of Service files" do
  include AuthenticationHelper

  describe "as admin" do
    before { login_as_admin }

    it "can be reached via Configuration" do
      visit spree.edit_admin_general_settings_path
      click_link "Terms of Service"
      expect(page).to have_content "No terms of services have been uploaded yet."
    end

    it "can be uploaded" do
      visit admin_terms_of_service_files_path
      attach_file "Attachment", Rails.root.join("public/Terms-of-service.pdf")
      click_button "Create Terms of service file"

      expect(page).to have_link "Terms of Service"
    end
  end
end
