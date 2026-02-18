# frozen_string_literal: true

# Request a JSON document from a DFC API authenticating as platform.
class DfcPlatformRequest
  def initialize(platform)
    @platform = platform
  end

  def call(url, data = nil, method: nil)
    OidcRequest.new(request_token).call(url, data, method:).body
  end

  def request_token
    connection = Faraday.new(
      request: { timeout: 5 },
    ) do |f|
      f.request :url_encoded
      f.response :json
      f.response :raise_error
    end

    url = ApiUser.token_endpoint(@platform)
    data = {
      grant_type: "client_credentials",
      client_id: ENV.fetch("OPENID_APP_ID", nil),
      client_secret: ENV.fetch("OPENID_APP_SECRET", nil),
      scope: "ReadEnterprise",
    }
    response = connection.post(url, data)
    response.body["access_token"]
  end
end
