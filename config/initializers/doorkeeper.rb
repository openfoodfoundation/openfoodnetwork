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

  default_scopes :profile
  enforce_configured_scopes

  access_token_expires_in 2.hours
  use_refresh_token
  hash_token_secrets
end
