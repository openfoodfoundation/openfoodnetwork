require 'spec_helper'

describe "General Settings" do
  include AuthenticationWorkflow

  before(:each) do
    quick_login_as_admin
    visit spree.admin_path
    click_link "Configuration"
    click_link "General Settings"
  end

  context "visiting general settings (admin)" do
    it "should have the right content" do
      page.should have_content("General Settings")
      find("#site_name").value.should == "Spree Demo Site"
      find("#site_url").value.should == "demo.spreecommerce.com"
    end
  end

  context "editing general settings (admin)" do
    it "should be able to update the site name" do
      fill_in "site_name", :with => "Spree Demo Site99"
      click_button "Update"

      assert_successful_update_message(:general_settings)

      find("#site_name").value.should == "Spree Demo Site99"
    end

    def assert_successful_update_message(resource)
      flash = Spree.t(:successfully_updated, resource: Spree.t(resource))
      within("[class='flash success']") do
        page.should have_content(flash)
      end
    end
  end
end
