# frozen_string_literal: true

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

  def show_social_icons?
    ContentConfig.footer_facebook_url.present? || ContentConfig.footer_twitter_url.present? ||
      ContentConfig.footer_instagram_url.present? || ContentConfig.footer_linkedin_url.present? ||
      ContentConfig.footer_googleplus_url.present? || ContentConfig.footer_pinterest_url.present?
  end
end
