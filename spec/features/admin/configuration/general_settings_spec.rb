require 'spec_helper'

describe "General Settings" do
  include AuthenticationHelper

  before(:each) do
    login_as_admin_and_visit spree.admin_dashboard_path
    click_link "Configuration"
    click_link "General Settings"
  end

  context "visiting general settings (admin)" do
    it "should have the right content" do
      expect(page).to have_content("General Settings")
      expect(find("#site_name").value).to eq("OFN Demo Site")
      expect(find("#site_url").value).to eq("demo.openfoodnetwork.org")
    end
  end

  context "editing general settings (admin)" do
    it "should be able to update the site name" do
      fill_in "site_name", with: "OFN Demo Site99"
      click_button "Update"

      assert_successful_update_message(:general_settings)

      expect(find("#site_name").value).to eq("OFN Demo Site99")
    end

    def assert_successful_update_message(resource)
      flash = Spree.t(:successfully_updated, resource: Spree.t(resource))
      within("[class='flash success']") do
        expect(page).to have_content(flash)
      end
    end
  end
end
