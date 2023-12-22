# frozen_string_literal: true

require 'system_helper'

describe 'Terms of Service banner' do
  include AuthenticationHelper

  let(:admin_user) { create(:admin_user, terms_of_service_accepted_at: nil) }
  let(:test_file) { "Terms-of-service.pdf" }
  let(:pdf_upload) do
    Rack::Test::UploadedFile.new(Rails.public_path.join(test_file), "application/pdf")
  end

  before do
    Spree::Config.enterprises_require_tos = true
    TermsOfServiceFile.create!(attachment: pdf_upload)
    login_as admin_user
  end

  context "when not accepted" do
    it "shows banner" do
      visit '/admin'

      expect(page).to have_content("Terms of Service have been updated")

      # Click on the accept button
      expect do
        click_button "Accept Terms of Service"
        admin_user.reload
      end.to change { admin_user.terms_of_service_accepted_at }
      expect(page).to_not have_content("Terms of Service have been updated")

      # Check the banner doesn't show again once ToS has been accepted
      page.refresh
      expect(page).to_not have_content("Terms of Service have been updated")
    end
  end

  context "when updating Terms of Service" do
    it "shows the banner" do
      # ToS has been accepted
      admin_user.update!(terms_of_service_accepted_at: 2.days.ago)

      # Upload new ToS
      visit admin_terms_of_service_files_path
      attach_file "Attachment", Rails.public_path.join(test_file)
      click_button "Create Terms of service file"

      # check it has been uploaded
      expect(page).to have_link "Terms of Service"

      expect(page).to have_content("Terms of Service have been updated")
    end
  end
end
