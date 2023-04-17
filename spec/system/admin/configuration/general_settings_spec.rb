# frozen_string_literal: true

require 'system_helper'

describe "General Settings" do
  include AuthenticationHelper

  before do
    login_as_admin
    visit spree.admin_dashboard_path
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
      update_and_assert_message
      expect(find("#site_name").value).to eq("OFN Demo Site99")
    end
  end

  context 'editing currency symbol position' do
    it 'updates its position' do
      expect(page).to have_content('CURRENCY SETTINGS')

      within('.currency') do
        find("[for='currency_symbol_position_after']").click
      end
      update_and_assert_message
      expect(page).to have_checked_field('10.00 $')
    end

    it "changes the currency decimal separator" do
      expect(Spree::Config.preferred_currency_decimal_mark).to eq('.')
      fill_in "currency_decimal_mark", with: ','
      update_and_assert_message
      expect(Spree::Config.preferred_currency_decimal_mark).to eq(',')
    end

    it "changes the currency thousands separator" do
      expect(Spree::Config.preferred_currency_thousands_separator).to eq(',')
      fill_in "currency_thousands_separator", with: '.'
      update_and_assert_message
      expect(Spree::Config.preferred_currency_thousands_separator).to eq('.')
    end
  end

  context "editing number localization preferences" do
    it "enables international thousand/decimal separator logic" do
      find("#enable_localized_number_").set "true"
      update_and_assert_message
      expect(Spree::Config.preferred_enable_localized_number?).to eq(true)
    end
  end
end

private

def update_and_assert_message
  click_button 'Update'
  within("[class='flash success']") do
    expect(page).to have_content("General Settings has been successfully updated!")
  end
end
