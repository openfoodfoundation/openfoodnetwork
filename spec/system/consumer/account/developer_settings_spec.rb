# frozen_string_literal: true

require "system_helper"

describe "Developer Settings" do
  include AuthenticationHelper
  include WebHelper

  describe "as a logged in user" do
    before do
      login_as user
      visit "/account"
    end

    context "when show_api_key_view is true" do
      let(:spree_api_key) { SecureRandom.hex(24) }
      let(:user) { create(:user, show_api_key_view: true, spree_api_key: spree_api_key) }

      it "shows the developer settings tab" do
        find("a", text: "DEVELOPER SETTINGS").click
        expect(page).to have_content "Developer Settings"
      end

      context "when the user has an api key" do
        before do
          find("a", text: "DEVELOPER SETTINGS").click
        end

        it "shows the api key" do
          expect(page).to have_input "api_key", with: spree_api_key
        end

        it "lets the user regenerate the api key" do
          click_button "Regenerate Key"
          expect(page).to have_content "Key generated"
          expect(page).to have_input "api_key", with: user.reload.spree_api_key
        end
      end
    end

    context "when show_api_key_view is false" do
      let(:user) { create(:user, show_api_key_view: false) }

      it "does not show the developer settings tab" do
        within("#account-tabs") do
          expect(page).to_not have_selector("a", text: "DEVELOPER SETTINGS")
        end
      end
    end
  end
end
