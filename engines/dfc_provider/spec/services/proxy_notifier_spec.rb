# frozen_string_literal: true

require_relative "../spec_helper"

# These tests depend on valid OpenID Connect client credentials in your
# `.env.test.local` file.
#
#     OPENID_APP_ID="..."
#     OPENID_APP_SECRET="..."
RSpec.describe ProxyNotifier do
  let(:platform) { "cqcm-dev" }
  let(:enterprise_url) { "http://ofn.example.net/api/dfc/enterprises/10000" }

  it "notifies the proxy", :vcr do
    # The test server is not reachable by the notified server.
    # If you don't have valid credentials, you'll get an unauthorized error.
    # Correctly authenticated, the server fails to update its data.
    expect {
      subject.refresh(platform, enterprise_url)
    }.to raise_error Faraday::ServerError
  end

  # Requires OIDC client secret for FDC dev realm.
  it "notifies Market Organic", :vcr do
    subject.refresh("mo-dev", enterprise_url)
  end
end
