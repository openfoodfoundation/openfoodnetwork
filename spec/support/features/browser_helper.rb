# frozen_string_literal: true

module Features
  module BrowserHelper
    def expect_browser_console_errors(count = 1)
      console_errors = page.driver.browser.manage.logs.get(:browser)
      expect(console_errors.count).to eq count
    end
  end
end
