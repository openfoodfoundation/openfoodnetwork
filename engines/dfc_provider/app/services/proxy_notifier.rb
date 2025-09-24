# frozen_string_literal: true

require "private_address_check"
require "private_address_check/tcpsocket_ext"

# Call a webhook to notify a data proxy about changes in our data.
class ProxyNotifier
  def refresh(platform)
    PrivateAddressCheck.only_public_connections do
      notify_proxy(platform)
    end
  end

  def request_token(platform)
    connection = Faraday.new(
      request: { timeout: 5 },
    ) do |f|
      f.request :url_encoded
      f.response :json
      f.response :raise_error
    end

    url = ApiUser.token_endpoint(platform)
    data = {
      grant_type: "client_credentials",
      client_id: ENV.fetch("OPENID_APP_ID", nil),
      client_secret: ENV.fetch("OPENID_APP_SECRET", nil),
      scope: "WriteEnterprise",
    }
    response = connection.post(url, data)
    response.body["access_token"]
  end

  def notify_proxy(platform)
    token = request_token(platform)
    data = {
      eventType: "refresh",
      enterpriseUrlid: DfcProvider::Engine.routes.url_helpers.enterprises_url,
      scope: "ReadEnterprise",
    }

    connection = Faraday.new(
      request: { timeout: 10 },
      headers: {
        'Authorization' => "Bearer #{token}",
      }
    ) do |f|
      f.request :json
      f.response :json
      f.response :raise_error
    end
    connection.post(webhook_url(platform), data)
  end

  def webhook_url(platform)
    platform_url = ApiUser.platform_url(platform)
    URI.parse(platform_url).tap do |url|
      url.path = "/djangoldp-dfc/webhook/"
    end
  end
end
