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
  end
end
