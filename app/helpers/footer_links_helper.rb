require 'web/cookies_consent'

module FooterLinksHelper
  def cookies_policy_link
    link_to( t( '.footer_data_cookies_policy' ),
             '',
             'cookies-policy-modal' => true,
             'cookies-banner' => !Web::CookiesConsent.new(cookies, request.host).exists? &&
                                   Spree::Config.cookies_consent_banner_toggle)
  end

  def privacy_policy_link
    link_to( t( '.footer_data_privacy_policy' ),
             Spree::Config.privacy_policy_url,
             target: '_blank',
             rel: 'noopener' )
  end
end
