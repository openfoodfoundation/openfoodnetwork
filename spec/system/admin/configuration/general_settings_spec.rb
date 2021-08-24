# frozen_string_literal: true

require "system_helper"

describe "General Settings" do
  include AuthenticationHelper

  before do
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

      within("[class='flash success']") do
        expect(page).to have_content(Spree.t(:successfully_updated,
                                             resource: Spree.t(:general_settings)))
      end
      expect(find("#site_name").value).to eq("OFN Demo Site99")
    end
  end

  context 'editing currency symbol position' do
    it 'updates its position' do
      expect(page).to have_content("CURRENCY SETTINGS")

      within('.currency') do
        find("[for='currency_symbol_position_after']").click
      end

      click_button 'Update'

      expect(page).to have_content(Spree.t(:successfully_updated,
                                           resource: Spree.t(:general_settings)))
      expect(page).to have_checked_field('10.00 $')
    end
  end
end
