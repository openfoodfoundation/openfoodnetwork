# frozen_string_literal: true

module CookieHelper
  def cookies_name
    Capybara.current_session.driver.browser.cookies
  end

  def cookies
    Capybara.current_session.driver.browser.cookies.all
  end
end
