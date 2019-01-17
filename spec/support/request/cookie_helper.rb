module CookieHelper
  def cookie_named(name)
    Capybara.current_session.driver.browser.manage.cookie_named(name)
  end
end
