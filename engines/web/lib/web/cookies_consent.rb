# frozen_string_literal: true

module Web
  class CookiesConsent
    COOKIE_NAME = 'cookies_consent'

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
        domain: domain,
        httponly: true
      }
    end

    private

    attr_reader :cookies, :domain
  end
end
