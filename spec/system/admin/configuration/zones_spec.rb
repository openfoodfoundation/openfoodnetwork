# frozen_string_literal: true

require 'system_helper'

describe "Zones" do
  include AuthenticationHelper
  include WebHelper

  it "list existing zones" do
    login_as_admin
    visit spree.edit_admin_general_settings_path
    create(:zone, name: "northern", description: "middle position alphabetically")
    create(:zone, name: "eastern", description: "zone is eastern")
    create(:zone, name: "western", description: "cool san fran")

    click_link "Zones"

    within_row(1) { expect(page).to have_content("eastern") }
    within_row(2) { expect(page).to have_content("northern") }
    within_row(3) { expect(page).to have_content("western") }

    click_link "zones_order_by_description_title"

    within_row(1) { expect(page).to have_content("western") }
    within_row(2) { expect(page).to have_content("northern") }
    within_row(3) { expect(page).to have_content("eastern") }
  end

  it "create a new zone" do
    login_as_admin
    visit spree.admin_zones_path
    click_link "admin_new_zone_link"
    expect(page).to have_content("New Zone")

    fill_in "zone_name", with: "japan"
    fill_in "zone_description", with: "japanese time zone"
    click_button "Create"

    expect(page).to have_content("successfully created!")
  end

  it "edit existing zone" do
    zone = create(:zone_with_member)
    login_as_admin
    visit spree.edit_admin_zone_path(zone.id)

    expect(page).to have_checked_field "country_based"

    # Toggle to state based zone
    choose "State Based"

    # click Add State
    page.find("#nested-state").click
    # select first state available
    find('.select2').find(:xpath, 'option[2]').select_option

    click_button "Update"
    expect(page).to have_content("successfully updated!")
  end
end
