# frozen_string_literal: true

module DiscourseHelper
  def discourse_configured?
    discourse_url.present?
  end

  def discourse_url
    ENV['DISCOURSE_URL']
  end

  def discourse_login_url
    discourse_url + '/login'
  end

  def discourse_sso_url
    discourse_url + '/session/sso_login'
  end

  def discourse_url!
    discourse_url || raise('Missing Discourse URL')
  end

  def discourse_sso_secret!
    ENV['DISCOURSE_SSO_SECRET'] || raise('Missing SSO secret')
  end
end
