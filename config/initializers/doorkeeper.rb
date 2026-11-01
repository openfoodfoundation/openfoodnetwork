# frozen_string_literal: true

# OAuth2 provider: external applications let OFN users log in with their
# OFN account. Applications are registered by super admins in
# Configuration > OAuth applications.
Doorkeeper.configure do
  orm :active_record

  # Reuse the OFN session. Guests log in and come back to the authorization.
  # Disabling a user revokes their tokens, see Spree::User.
  resource_owner_authenticator do
    user = request.env["warden"].user(:spree_user)

    if user.nil? || user.disabled
      redirect_to main_app.root_path(anchor: "/login", after_login: request.fullpath)
    else
      user
    end
  end

  grant_flows %w[authorization_code]
  # Public applications (mobile, browser) can't keep a secret: PKCE replaces it.
  force_pkce
  pkce_code_challenge_methods %w[S256]

  # OpenID Connect scopes, see config/initializers/doorkeeper_openid_connect.rb.
  default_scopes :openid
  optional_scopes :email
  enforce_configured_scopes

  # The time the user logged in, for OpenID Connect. It's always taken from the
  # session, never from the authorization request.
  custom_access_token_attributes [:auth_time]
  after_successful_authorization do |controller, context|
    grant = context.auth.try(:auth).try(:token)
    next unless grant.is_a?(Doorkeeper::AccessGrant)

    auth_time = controller.session.dig("warden.user.spree_user.session", "auth_time")
    grant.update_columns(auth_time: auth_time && Time.zone.at(auth_time))
  end

  access_token_expires_in 2.hours
  use_refresh_token
  hash_token_secrets
end
