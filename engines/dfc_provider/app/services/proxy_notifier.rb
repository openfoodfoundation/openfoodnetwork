# frozen_string_literal: true

# Call a webhook to notify a data proxy about changes in our data.
class ProxyNotifier
  def refresh(platform, enterprise_url)
    endpoint = ApiUser.webhook_url(platform)
    data = {
      eventType: "refresh",
      enterpriseUrlid: enterprise_url,
      scope: "ReadEnterprise",
    }
    api = DfcPlatformRequest.new(platform)
    api.call(endpoint, data)
  end
end
