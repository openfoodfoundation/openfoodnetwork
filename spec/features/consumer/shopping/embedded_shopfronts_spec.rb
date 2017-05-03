require 'spec_helper'

feature "Using embedded shopfront functionality", js: true do
  include AuthenticationWorkflow
  include WebHelper

  describe "enabling embedded shopfronts" do
    before do
      Spree::Config[:enable_embedded_shopfronts] = false
    end

    it "disables iframes by default" do
      visit shops_path
      expect(page.response_headers['X-Frame-Options']).to eq 'DENY'
      expect(page.response_headers['Content-Security-Policy']).to eq "frame-ancestors 'none'"
    end

    it "allows iframes on certain pages when enabled in configuration" do
      quick_login_as_admin

      visit spree.edit_admin_general_settings_path

      check 'enable_embedded_shopfronts'
      fill_in 'embedded_shopfronts_whitelist', with: "test.com"

      click_button 'Update'

      visit shops_path
      expect(page.response_headers['X-Frame-Options']).to be_nil
      expect(page.response_headers['Content-Security-Policy']).to eq "frame-ancestors test.com"
    end
  end

  describe "using iframes", js: true do
    before do
      Spree::Config[:enable_embedded_shopfronts] = true
    end

    after do
      Spree::Config[:enable_embedded_shopfronts] = false
    end

    pending "displays iframe content" do
      Capybara.current_session.driver.visit('spec/dummy/iframe_test.html')

      expect(page).to have_text 'Iframe Test'
      expect(page).to have_selector 'iframe#test_iframe'

      within_frame 'test_iframe' do
        sleep 1
        expect(page).to have_content "OFN" # currently fails...
      end
    end
  end
end
