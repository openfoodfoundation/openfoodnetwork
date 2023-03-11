# frozen_string_literal: true

require 'system_helper'

describe "Terms of Service files" do
  include AuthenticationHelper

  describe "as admin" do
    let(:test_file_path) { "public/Terms-of-service.pdf" }

    before { login_as_admin }

    it "can be reached via Configuration" do
      visit spree.edit_admin_general_settings_path
      click_link "Terms of Service"

      expect(page).to have_content "No terms of services have been uploaded yet."
      expect(page).to have_content "your old Terms of service"
      expect(page).to have_link "Terms of service", href: "/Terms-of-service.pdf"
    end

    it "can be uploaded" do
      visit admin_terms_of_service_files_path
      attach_file "Attachment", Rails.root.join(test_file_path)
      click_button "Create Terms of service file"

      expect(page).to have_link "Terms of Service"
    end

    it "provides Rails' standard action for a new file" do
      visit new_admin_terms_of_service_files_path
      expect(page).to have_button "Create Terms of service file"
    end

    it "can delete the current file" do
      attachment = File.open(Rails.root.join(test_file_path))
      file = Rack::Test::UploadedFile.new(attachment, "application/pdf")
      TermsOfServiceFile.create!(attachment: file)

      visit admin_terms_of_service_files_path

      accept_alert { click_link "Delete" }

      expect(page).to have_content "No terms of services have been uploaded yet."
    end
  end
end
