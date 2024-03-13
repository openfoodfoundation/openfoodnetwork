# frozen_string_literal: true

require "private_address_check"
require "private_address_check/tcpsocket_ext"

# Request a JSON document from a DFC API with authentication.
class DfcRequest
  def initialize(user)
    @user = user
  end

  def get(url)
    connection = Faraday.new(
      request: { timeout: 30 },
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{@user.oidc_account.token}",
      }
    )
    response = only_public_connections do
      connection.get(url)
    end

    response.body
  end

  private

  def only_public_connections(&)
    return yield if Rails.env.development?

    PrivateAddressCheck.only_public_connections(&)
  end
end
