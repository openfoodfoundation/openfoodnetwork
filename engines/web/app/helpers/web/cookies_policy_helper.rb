# frozen_string_literal: true

module Web
  module CookiesPolicyHelper
    def render_cookie_entry(cookie_name, cookie_desc, cookie_domain = nil)
      render partial: 'cookies_policy_entry',
             locals: { cookie_name: cookie_name,
                       cookie_desc: cookie_desc,
                       cookie_domain: cookie_domain }
    end

    def matomo_iframe_src
      "#{Spree::Config.matomo_url}" \
        "/index.php?module=CoreAdminHome&action=optOut" \
        "&language=#{locale_language}" \
        "&backgroundColor=&fontColor=222222&fontSize=16px&" \
        "fontFamily=%22Roboto%22%2C%20Arial%2C%20sans-serif"
    end

    # removes country from locale if needed
    #   for example, both locales en and en_GB return language en
    def locale_language
      I18n.locale[0..1]
    end
  end
end
