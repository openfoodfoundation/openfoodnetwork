require 'discourse/single_sign_on'

class DiscourseSsoController < ApplicationController
  include SharedHelper

  def sso
    if spree_current_user
      begin
        redirect_to sso_url
      rescue TypeError
        render text: "Bad SingleSignOn request.", status: :bad_request
      end
    else
      redirect_to login_path
    end
  end

  def sso_url
    secret = ENV['DISCOURSE_SSO_SECRET'] or raise 'Missing SSO secret'
    discourse_url = ENV['DISCOURSE_SSO_URL'] or raise 'Missing Discourse SSO login URL.'
    sso = Discourse::SingleSignOn.parse(request.query_string, secret)
    sso.email = spree_current_user.email
    sso.username = spree_current_user.login
    sso.external_id = spree_current_user.id
    sso.sso_secret = secret
    sso.admin = admin_user?
    sso.require_activation = require_activation?
    sso.to_url(discourse_url)
  end

  def require_activation?
    !admin_user? && !email_validated?
  end

  def email_validated?
    spree_current_user.confirmed.map(&:email).include?(spree_current_user.email)
  end
end
