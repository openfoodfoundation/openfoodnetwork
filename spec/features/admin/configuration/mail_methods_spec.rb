# frozen_string_literal: true

require 'spec_helper'

describe "Mail Methods" do
  include AuthenticationHelper

  before(:each) do
    login_as_admin_and_visit spree.edit_admin_general_settings_path
  end

  context "edit" do
    before(:each) do
      click_link "Mail Method Settings"
    end

    it "should be able to edit mail method settings" do
      fill_in "mail_bcc", with: "ofn@example.com"
      click_button "Update"
      expect(page).to have_content("successfully updated!")
    end
  end
end
