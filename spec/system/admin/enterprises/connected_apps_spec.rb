# frozen_string_literal: true

require "system_helper"

RSpec.describe "Connected Apps", feature: :connected_apps, vcr: true do
  let(:enterprise) { create(:enterprise) }

  before do
    login_as enterprise.owner
  end

  it "is only visible when feature is enabled" do
    allow(Spree::Config).to receive(:connected_apps_enabled).
      and_return("discover_regen,affiliate_sales_data")

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

  it "is only visible when setting is enabled" do
    allow(Spree::Config).to receive(:connected_apps_enabled).and_return(nil)
    visit edit_admin_enterprise_path(enterprise)
    expect(page).not_to have_content "CONNECTED APPS"

    allow(Spree::Config).to receive(:connected_apps_enabled).
      and_return("discover_regen,affiliate_sales_data")
    visit edit_admin_enterprise_path(enterprise)
    expect(page).to have_content "CONNECTED APPS"
  end

  it "only shows enabled apps" do
    allow(Spree::Config).to receive(:connected_apps_enabled).and_return("discover_regen")

    visit "#{edit_admin_enterprise_path(enterprise)}#/connected_apps_panel"

    expect(page).to have_selector "h3", text: "Discover Regenerative"
    expect(page).not_to have_selector "h3", text: "INRAE / UFC QUE CHOISIR Research"
  end

  describe "Discover Regenerative" do
    before do
      allow(Spree::Config).to receive(:connected_apps_enabled).and_return("discover_regen")
    end
    let(:section_heading) { self.class.description }

    it "can be enabled and disabled" do
      visit edit_admin_enterprise_path(enterprise)

      scroll_to :bottom
      click_link "Connected apps"

      within section_containing_heading do
        click_button "Allow data sharing"
      end

      # (page is reloaded so we need to evaluate within block again)
      within section_containing_heading do
        expect(page).not_to have_button "Allow data sharing"
        expect(page).to have_button "Loading", disabled: true

        perform_enqueued_jobs(only: ConnectAppJob)

        expect(page).not_to have_button "Loading", disabled: true
        expect(page).to have_content "account is connected"
        expect(page).to have_link "Manage listing"

        click_button "Stop sharing"
      end

      within section_containing_heading do
        expect(page).to have_button "Allow data sharing"
        expect(page).not_to have_button "Stop sharing"
        expect(page).not_to have_content "account is connected"
        expect(page).not_to have_link "Manage listing"
      end
    end

    it "can't be enabled by non-manager" do
      login_as create(:admin_user)

      visit "#{edit_admin_enterprise_path(enterprise)}#/connected_apps_panel"

      within section_containing_heading do
        expect(page).to have_button("Allow data sharing", disabled: true)
        expect(page).to have_content "Only managers can connect apps."
      end
    end
  end

  describe "Affiliate Sales Data" do
    before do
      allow(Spree::Config).to receive(:connected_apps_enabled).and_return("affiliate_sales_data")
    end
    let(:section_heading) { "INRAE / UFC QUE CHOISIR Research" }

    it "can be enabled and disabled" do
      visit edit_admin_enterprise_path(enterprise)

      scroll_to :bottom
      click_link "Connected apps"

      within section_containing_heading do
        click_button "Allow data sharing"
      end

      # (page is reloaded so we need to evaluate within block again)
      within section_containing_heading do
        expect(page).not_to have_button "Allow data sharing"
        click_button "Stop sharing"
      end

      within section_containing_heading do
        expect(page).to have_button "Allow data sharing"
        expect(page).not_to have_button "Stop sharing"
      end
    end

    it "can't be enabled by non-manager" do
      login_as create(:admin_user)

      visit "#{edit_admin_enterprise_path(enterprise)}#/connected_apps_panel"

      within section_containing_heading do
        expect(page).to have_button("Allow data sharing", disabled: true)
        expect(page).to have_content "Only managers can connect apps."
      end
    end
  end

  def section_containing_heading(heading = section_heading)
    page.find("h3", text: heading).ancestor("section")
  end
end
