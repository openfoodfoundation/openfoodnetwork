class CookiesConsent
  COOKIE_NAME = 'cookies_consent'.freeze

  def initialize(cookies, domain)
    @cookies = cookies
    @domain = domain
  end

  def exists?
    cookies.key?(COOKIE_NAME)
  end

  def destroy
    cookies.delete(COOKIE_NAME, domain: domain)
  end

  def set
    cookies[COOKIE_NAME] = {
      value: COOKIE_NAME,
      expires: 1.year.from_now,
      domain: domain
    }
  end

  private

  attr_reader :cookies, :domain
end
