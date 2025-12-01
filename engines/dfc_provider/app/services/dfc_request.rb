# frozen_string_literal: true

# Request a JSON document from a DFC API with authentication.
#
# All DFC API interactions are authenticated via OIDC tokens. If the user's
# access token is expired, we try to get a new one with the user's refresh
# token.
class DfcRequest
  def initialize(user)
    @user = user
  end

  def call(url, data = nil, method: nil)
    begin
      request = OidcRequest.new(@user.oidc_account.token)
      response = request.call(url, data, method:)
    rescue Faraday::UnauthorizedError, Faraday::ForbiddenError
      raise unless token_stale?

      # If access was denied and our token is stale then refresh and retry:
      refresh_access_token!
      request = OidcRequest.new(@user.oidc_account.token)
      response = request.call(url, data, method:)
    end

    response.body
  end

  private

  def token_stale?
    @user.oidc_account.updated_at < 15.minutes.ago
  end

  def refresh_access_token!
    strategy = OmniAuth::Strategies::OpenIDConnect.new(
      Rails.application,
      Devise.omniauth_configs[:openid_connect].options
      # Don't try to call `Devise.omniauth(:openid_connect)` first.
      # It results in an empty config hash and we lose our config.
    )
    client = strategy.client
    client.token_endpoint = strategy.config.token_endpoint
    client.refresh_token = @user.oidc_account.refresh_token

    token = client.access_token!

    @user.oidc_account.update!(
      token: token.access_token,
      refresh_token: token.refresh_token
    )
  rescue Rack::OAuth2::Client::Error
    @user.oidc_account.update!(token: nil, refresh_token: nil)
    raise
  end
end
