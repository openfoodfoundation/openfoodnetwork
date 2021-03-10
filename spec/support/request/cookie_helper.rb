# frozen_string_literal: true

module CookieHelper
  def cookie_named(name)
    Capybara.current_session.driver.browser.manage.cookie_named(name)
  end

  def cookies
    Capybara.current_session.driver.browser.manage.all_cookies
  end
end
