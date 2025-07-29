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

    # The component displays something and then replaces it with the real
    # list. That leads to a race condition and we have to just wait until
    # the component is loaded. :-(
    sleep 10

    within(platform_list("without-permissions")) do
      expect(page).to have_content "Proxy Dev Portal"

      # NotSupportedError: Failed to execute 'evaluate' on 'Document':
      # The node provided is '#document-fragment', which is not a valid context node type.
      #
      # click_on "Agree and share"

      # This hack works
      find("button", text: "Agree and share").native.trigger("click")
    end

    sleep 5
    within(platform_list("approved")) do
      expect(page).to have_content "Proxy Dev Portal"
      find("button", text: "Stop sharing").native.trigger("click")
    end

    sleep 5
    within(platform_list("without-permissions")) do
      expect(page).to have_content "Proxy Dev Portal"
      find("button", text: "Agree and share").native.trigger("click")
    end

    sleep 5
    within(platform_list("approved")) do
      expect(page).to have_content "Proxy Dev Portal"
    end
  end

  def platform_list(variant)
    page.find('solid-permissioning').shadow_root
      .find("platform-block[variant='#{variant}']").shadow_root
  end
end
