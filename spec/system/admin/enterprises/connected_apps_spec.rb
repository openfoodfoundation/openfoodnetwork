# frozen_string_literal: true

require "system_helper"

describe "Connected Apps", feature: :connected_apps, vcr: true do
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
    expect(page).to_not have_content "CONNECTED APPS"

    Flipper.enable(:connected_apps, enterprise.owner)
    visit edit_admin_enterprise_path(enterprise)
    expect(page).to have_content "CONNECTED APPS"

    Flipper.disable(:connected_apps)
    Flipper.enable(:connected_apps, enterprise)
    visit edit_admin_enterprise_path(enterprise)
    expect(page).to have_content "CONNECTED APPS"
  end

  it "can be enabled" do
    visit edit_admin_enterprise_path(enterprise)

    scroll_to :bottom
    click_link "Connected apps"
    expect(page).to have_content "Discover Regenerative"

    click_button "Share data"
    expect(page).to_not have_button "Share data"
    expect(page).to have_content "Saving changes"

    perform_enqueued_jobs(only: ConnectAppJob)
    page.refresh # TODO: update via cable_ready
    expect(page).to have_content "include regenerative details"
    expect(page).to have_link "Update details"
  end
end
