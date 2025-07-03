# frozen_string_literal: true

require "system_helper"

RSpec.describe "DFC Permissions", feature: "cqcm-dev", vcr: true do
  let(:enterprise) { create(:enterprise) }

  before do
    login_as enterprise.owner
  end

  it "is not visible when no platform is enabled" do
    Flipper.disable("cqcm-dev")
    visit edit_admin_enterprise_path(enterprise)
    expect(page).not_to have_content "CONNECTED APPS"
  end

  it "can share data with another platform" do
    visit edit_admin_enterprise_path(enterprise)

    scroll_to :bottom
    click_link "Connected apps"

    # TODO: interact with shadow root of web component
    #
    # expect(page).to have_content "Proxy Dev Portal"
    # expect(page).to have_selector "svg.unchecked" # permission not granted

    # click_on "Agree and share"
    # expect(page).to have_selector "svg.checked" # permission granted
  end
end
