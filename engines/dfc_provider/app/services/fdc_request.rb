# frozen_string_literal: true

require "private_address_check"
require "private_address_check/tcpsocket_ext"

# Request a JSON document from the FDC API with authentication.
#
# Currently, the API doesn't quite comply with the DFC standard and we need
# to authenticate a little bit differently.
#
# And then we get slightly different data as well.
class FdcRequest < DfcRequest
  # Override main method to POST authorization data.
  def call(url, data = {})
    response = request(url, auth_data.merge(data).to_json)

    if response.status >= 400 && token_stale?
      refresh_access_token!
      response = request(url, auth_data.merge(data).to_json)
    end

    response.body
  end

  private

  def auth_data
    {
      userId: @user.oidc_account.uid,
      accessToken: @user.oidc_account.token,
    }
  end
end
