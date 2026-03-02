# frozen_string_literal: true

require "system_helper"

RSpec.describe "DFC Permissions", feature: "cqcm-dev", vcr: true do
  let(:enterprise) { create(:enterprise) }

  before do
    skip "Puffing Billy seems to make our rspec processes hang at the end."
  end

  before do
    login_as enterprise.owner

    # Disable data proxy webhook which can't reach our test server.
    allow_any_instance_of(ProxyNotifier).to receive(:refresh)
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
    wait_for_component_loaded

    within(platform_list("without-permissions")) do
      expect(page).to have_content "Proxy Dev Portal"

      # NotSupportedError: Failed to execute 'evaluate' on 'Document':
      # The node provided is '#document-fragment', which is not a valid context node type.
      #
      # click_on "Agree and share"

      # This hack works
      find("button", text: "Agree and share").native.trigger("click")
    end

    within_platform_list("approved") do
      expect(page).to have_content "Proxy Dev Portal"
      find("button", text: "Stop sharing").native.trigger("click")
    end

    within_platform_list("without-permissions") do
      expect(page).to have_content "Proxy Dev Portal"
      find("button", text: "Agree and share").native.trigger("click")
    end

    within_platform_list("approved") do
      expect(page).to have_content "Proxy Dev Portal"
    end
  end

  def wait_for_component_loaded
    retry_expectations do
      within(page.find('solid-permissioning').shadow_root) do
        expect(page).to have_content "APPROVED PLATFORMS"
      end
    end
  end

  def within_platform_list(variant, &)
    retry_expectations(on: Ferrum::JavaScriptError) do
      within(platform_list(variant), &)
    end
  end

  # Handy helper adopted from CERES Fair Food and modified.
  # We may want to share this but don't have a need for it now.
  def retry_expectations(on: RSpec::Expectations::ExpectationNotMetError)
    start = Time.now.utc
    finish = start + Capybara.default_max_wait_time

    yield
  rescue on
    raise if Time.now.utc > finish

    sleep 0.1
    retry
  end

  def platform_list(variant)
    page.find('solid-permissioning').shadow_root
      .find("platform-block[variant='#{variant}']").shadow_root
  end
end
