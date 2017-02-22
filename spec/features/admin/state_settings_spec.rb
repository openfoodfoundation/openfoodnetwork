require 'spec_helper'

feature %q{
    As an administrator
    I want to change the way states are displayed to users
} do
  include AuthenticationWorkflow
  include WebHelper

	describe "state settings" do
		scenario "changing the state display preference settings to name" do
			login_to_admin_section
    		visit spree.edit_admin_general_settings_path
    		select("name", :from => 'state_display')
    		click_button "Update"
			page.should have_content "General Settings has been successfully updated!"

            Spree::Config[:state_display].should == "name"

		end

		scenario "changing the state display preference settings to abbr" do
			login_to_admin_section
    		visit spree.edit_admin_general_settings_path
    		select("abbr", :from => 'state_display')
    		click_button "Update"
            page.should have_content "General Settings has been successfully updated!"

            Spree::Config[:state_display].should == "abbr"

		end
	end
end