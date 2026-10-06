# frozen_string_literal: true

require "open_food_network/oidc_secrets"

# OpenID Connect on top of the OAuth2 provider (config/initializers/doorkeeper.rb):
# ID tokens, standard user info and discovery at /.well-known/openid-configuration.
Doorkeeper::OpenidConnect.configure do
  issuer do |_resource_owner, _application, _request|
    "#{Rails.env.local? ? 'http' : 'https'}://#{ENV.fetch('SITE_URL')}"
  end

  protocol { Rails.env.local? ? :http : :https }

  # Endpoints are published on the issuer's host, even when discovery is
  # requested through another domain name.
  discovery_url_options do |_request|
    %i[authorization token revocation introspection userinfo jwks].index_with do
      { host: ENV.fetch("SITE_URL") }
    end
  end

  signing_key -> { OpenFoodNetwork::OidcSecrets.signing_keys }

  # Each application gets its own identifier for a user, so applications can't
  # match their users with each other.
  subject_types_supported [:pairwise]

  subject do |resource_owner, application|
    OpenSSL::HMAC.hexdigest("SHA256", OpenFoodNetwork::OidcSecrets.pairwise_secret,
                            "#{application.uid}:#{resource_owner.id}")
  end

  resource_owner_from_access_token do |access_token|
    Spree::User.find_by(id: access_token.resource_owner_id)
  end

  # The time the user typed their password: set at login by the Warden hook
  # below, and stored with the grant and its tokens (see
  # config/initializers/doorkeeper.rb) so that refreshed ID tokens keep it.
  auth_time_from_session do |session, _request|
    session.dig("warden.user.spree_user.session", "auth_time")
  end
  auth_time_from_access_token(&:auth_time)

  # OFN has no account chooser: choosing another account means logging in again.
  log_in_again = lambda do |_resource_owner, return_to|
    request.env["warden"].logout(:spree_user)
    redirect_to main_app.root_path(anchor: "/login", after_login: return_to)
  end
  reauthenticate_resource_owner(&log_in_again)
  select_account_for_resource_owner(&log_in_again)

  claims do
    normal_claim :email, scope: :email, response: %i[id_token user_info] do |user, _scopes, _token|
      user.email
    end

    normal_claim :email_verified, scope: :email,
                                  response: %i[id_token user_info] do |user, _scopes, _token|
      user.confirmed?
    end
  end
end

# A login from the remember me cookie isn't an authentication of the user.
Warden::Manager.after_authentication(scope: :spree_user) do |_user, warden, options|
  next if warden.winning_strategy.is_a?(Devise::Strategies::Rememberable)

  warden.session(options[:scope])["auth_time"] = Time.zone.now.to_i
end

Rails.application.config.after_initialize do
  next if Rails.env.local? || OpenFoodNetwork::OidcSecrets.missing.empty?

  Rails.logger.warn(
    "OpenID Connect needs #{OpenFoodNetwork::OidcSecrets.missing.join(' and ')} " \
    "before enabling the oauth_provider feature."
  )
end
