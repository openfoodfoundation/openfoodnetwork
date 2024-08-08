# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Connected App Settings", feature: :connected_apps do
  include AuthenticationHelper

  before do
    login_as_admin
    visit spree.admin_dashboard_path
    click_link "Configuration"
    click_link "Connected app settings"
  end

  it "should update connected app enabled preferences" do
    expect(page).to have_field "Discover Regenerative portal", checked: false
    expect(page).to have_field "DFC anonymised orders API for research purposes", checked: false

    check "Discover Regenerative portal"
    check "DFC anonymised orders API for research purposes"

    expect{
      click_button "Update"
    }.to change{ Spree::Config.connected_apps_enabled }.to("discover_regen,affiliate_sales_data")

    expect(page).to have_field "Discover Regenerative portal", checked: true
    expect(page).to have_field "DFC anonymised orders API for research purposes", checked: true

    uncheck "Discover Regenerative portal"
    uncheck "DFC anonymised orders API for research purposes"

    expect{
      click_button "Update"
    }.to change{ Spree::Config.connected_apps_enabled }.to("")
  end
end
