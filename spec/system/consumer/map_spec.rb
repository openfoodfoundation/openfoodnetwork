# frozen_string_literal: true

require 'system_helper'

RSpec.describe 'Map' do
  context 'map can load' do
    it 'does not show alert' do
      url_whitelist = page.driver.browser.url_whitelist
      page.driver.browser.url_whitelist = nil

      assert_raises(Capybara::ModalNotFound) do
        accept_alert { visit '/map' }
      end

      page.driver.browser.url_whitelist = url_whitelist
    end
  end

  context 'map cannot load' do
    it 'shows alert' do
      message = accept_alert { visit '/map' }
      expect(message).to eq("Unable to load map.
      Please check your browser settings
      and allow 3rd party cookies for this website.".squish)
    end
  end
end
