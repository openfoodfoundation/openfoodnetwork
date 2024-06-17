# frozen_string_literal: true

require "system_helper"

RSpec.describe "Connected Apps", feature: :connected_apps, vcr: true do
  let(:enterprise) { create(:enterprise) }

  before do
    login_as enterprise.owner
  end

  it "is only visible when enabled" do
    # Assuming that this feature will be the default one day, I'm treating this
    # as special case and disable the feature. I don't want to wrap all other
    # test cases in a context block for the feature toggle which will need
    # removing one day.
    Flipper.disable(:connected_apps)
    visit edit_admin_enterprise_path(enterprise)
    expect(page).not_to have_content "CONNECTED APPS"

    Flipper.enable(:connected_apps, enterprise.owner)
    visit edit_admin_enterprise_path(enterprise)
    expect(page).to have_content "CONNECTED APPS"

    Flipper.disable(:connected_apps)
    Flipper.enable(:connected_apps, enterprise)
    visit edit_admin_enterprise_path(enterprise)
    expect(page).to have_content "CONNECTED APPS"
  end

  it "can be enabled and disabled" do
    visit edit_admin_enterprise_path(enterprise)

    scroll_to :bottom
    click_link "Connected apps"
    expect(page).to have_content "Discover Regenerative"

    click_button "Allow data sharing"
    expect(page).not_to have_button "Allow data sharing"
    expect(page).to have_button "Loading", disabled: true

    perform_enqueued_jobs(only: ConnectAppJob)
    expect(page).not_to have_button "Loading", disabled: true
    expect(page).to have_content "account is connected"
    expect(page).to have_link "Manage listing"

    click_button "Stop sharing"
    expect(page).to have_button "Allow data sharing"
    expect(page).not_to have_button "Stop sharing"
    expect(page).not_to have_content "account is connected"
    expect(page).not_to have_link "Manage listing"
  end

  it "can't be enabled by non-manager" do
    login_as create(:admin_user)

    visit "#{edit_admin_enterprise_path(enterprise)}#/connected_apps_panel"
    expect(page).to have_content "Discover Regenerative"

    expect(page).to have_button("Allow data sharing", disabled: true)
    expect(page).to have_content "Only managers can connect apps."
  end
end
