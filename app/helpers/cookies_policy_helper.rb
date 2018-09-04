module CookiesPolicyHelper
  def render_cookie_entry(cookie_name, cookie_desc, cookie_domain = nil)
    render partial: 'cookies_policy_entry',
           locals: { cookie_name: cookie_name,
                     cookie_desc: cookie_desc,
                     cookie_domain: cookie_domain }
  end
end
