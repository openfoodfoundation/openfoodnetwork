require 'spec_helper'

describe "Mail Methods" do
  include AuthenticationWorkflow

  before(:each) do
    quick_login_as_admin
    visit spree.admin_dashboard_path
    click_link "Configuration"
  end

  context "edit" do
    before(:each) do
      click_link "Mail Method Settings"
    end

    it "should be able to edit mail method settings" do
      fill_in "mail_bcc", with: "spree@example.com99"
      click_button "Update"
      expect(page).to have_content("successfully updated!")
    end
  end
end
