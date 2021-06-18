# frozen_string_literal: true

require 'discourse/single_sign_on'

class DiscourseSsoController < ApplicationController
  include SharedHelper
  include DiscourseHelper

  before_action :require_config

  def login
    if require_activation?
      redirect_to discourse_url
    else
      redirect_to discourse_login_url
    end
  end

  def sso
    if spree_current_user
      begin
        redirect_to sso_url
      rescue TypeError
        render plain: "Bad SingleSignOn request.", status: :bad_request
      end
    else
      redirect_to login_path
    end
  end

  private

  def sso_url
    secret = discourse_sso_secret!
    sso = Discourse::SingleSignOn.parse(request.query_string, secret)
    sso.email = spree_current_user.email
    sso.username = spree_current_user.login
    sso.external_id = spree_current_user.id
    sso.sso_secret = secret
    sso.admin = admin_user?
    sso.require_activation = require_activation?
    sso.to_url(discourse_sso_url)
  end

  def require_config
    raise ActionController::RoutingError, 'Not Found' unless discourse_configured?
  end

  def require_activation?
    !admin_user? && !spree_current_user.confirmed?
  end
end
