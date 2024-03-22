# frozen_string_literal: true

require "private_address_check"
require "private_address_check/tcpsocket_ext"

# Request a JSON document from a DFC API with authentication.
#
# All DFC API interactions are authenticated via OIDC tokens. If the user's
# access token is expired, we try to get a new one with the user's refresh
# token.
class DfcRequest
  def initialize(user)
    @user = user
  end

  def call(url, data = nil)
    response = request(url, data)

    if response.status >= 400 && token_stale?
      refresh_access_token!
      response = request(url, data)
    end

    response.body
  end

  private

  def request(url, data = nil)
    only_public_connections do
      if data
        connection.post(url, data)
      else
        connection.get(url)
      end
    end
  end

  def token_stale?
    @user.oidc_account.updated_at < 15.minutes.ago
  end

  def connection
    Faraday.new(
      request: { timeout: 30 },
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{@user.oidc_account.token}",
      }
    )
  end

  def only_public_connections(&)
    return yield if Rails.env.development?

    PrivateAddressCheck.only_public_connections(&)
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
  end
end
