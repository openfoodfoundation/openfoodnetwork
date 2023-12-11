# frozen_string_literal: true

require "system_helper"

describe "Connected Apps", feature: :connected_apps do
  let(:enterprise) { create(:enterprise) }

  before do
    login_as enterprise.owner
  end

  it "is not visible by default" do
    # Assuming that this feature will be the default one day, I'm treating this
    # as special case and disable the feature. I don't want to wrap all other
    # test cases in a context block for the feature toggle which will need
    # removing one day.
    Flipper.disable(:connected_apps)
    visit edit_admin_enterprise_path(enterprise)
    expect(page).to_not have_content "CONNECTED APPS"
  end

  it "is visible" do
    visit edit_admin_enterprise_path(enterprise)
    expect(page).to have_content "CONNECTED APPS"

    scroll_to :bottom
    click_link "Connected apps"
    expect(page).to have_content "in progress"
  end
end
