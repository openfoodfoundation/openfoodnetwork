# frozen_string_literal: true

require "private_address_check"
require "private_address_check/tcpsocket_ext"

# Request a JSON document with an OIDC token.
class OidcRequest
  def initialize(token)
    @token = token
  end

  def call(url, data = nil, method: nil)
    request(url, data, method:)
  rescue StandardError => e
    Alert.raise(e, { dfc_request: { data: } })
    raise
  end

  private

  def request(url, data = nil, method: nil)
    only_public_connections do
      if method == :put
        connection.put(url, data)
      elsif data
        connection.post(url, data)
      else
        connection.get(url)
      end
    end
  end

  def connection
    Faraday.new(
      request: { timeout: 30 },
      headers: {
        'Authorization' => "Bearer #{@token}",
      }
    ) do |f|
      f.request :json
      f.response :json

      # Configure Faraday to raise errors on status 4xx and 5xx responses.
      f.response :raise_error
    end
  end

  def only_public_connections(&)
    return yield if Rails.env.development?

    PrivateAddressCheck.only_public_connections(&)
  end
end
