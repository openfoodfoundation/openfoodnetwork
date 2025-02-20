# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcRequest do
  subject(:api) { DfcRequest.new(user) }

  let(:user) { build(:oidc_user) }
  let(:account) { user.oidc_account }

  it "gets a DFC document" do
    stub_request(:get, "http://example.net/api").
      to_return(status: 200, body: '{"@context":"/"}')

    expect(api.call("http://example.net/api")).to eq '{"@context":"/"}'
  end

  it "posts a DFC document" do
    json = '{"name":"new season apples"}'
    stub_request(:post, "http://example.net/api").
      with(body: json).
      to_return(status: 201) # Created

    expect(api.call("http://example.net/api", json)).to eq ""
  end

  it "refreshes the access token on fail", vcr: true do
    # Live VCR recordings require the following secret ENV variables:
    # - OPENID_APP_ID
    # - OPENID_APP_SECRET
    # - OPENID_REFRESH_TOKEN
    # You can set them in the .env.test.local file.

    stub_request(:get, "http://example.net/api").
      to_return(status: 401)

    # A refresh is only attempted if the token is stale.
    account.refresh_token = ENV.fetch("OPENID_REFRESH_TOKEN")
    account.updated_at = 1.day.ago

    expect { api.call("http://example.net/api") }
      .to raise_error(Faraday::UnauthorizedError)
      .and change { account.token }
      .and change { account.refresh_token }
  end

  it "doesn't try to refresh the token when it's still fresh" do
    stub_request(:get, "http://example.net/api").
      to_return(status: 401)

    user.oidc_account.updated_at = 1.minute.ago

    expect { api.call("http://example.net/api") }
      .to raise_error(Faraday::UnauthorizedError)

    # Trying to reach the OIDC server via network request to refresh the token
    # would raise errors because we didn't setup Webmock or VCR.
    # The absence of errors makes this test pass.
  end

  it "clears invalid refresh tokens", vcr: true do
    stub_request(:get, "http://example.net/api").to_return(status: 401)

    account.refresh_token = "some-invalid-token"
    account.updated_at = 1.day.ago

    expect { api.call("http://example.net/api") }
      .to raise_error(Rack::OAuth2::Client::Error)

    expect(account.refresh_token).to eq nil
  end

  it "refreshes the access token and retrieves the FDC catalog", vcr: true do
    # A refresh is only attempted if the token is stale.
    account.uid = "testdfc@protonmail.com"
    account.refresh_token = ENV.fetch("OPENID_REFRESH_TOKEN")
    account.updated_at = 1.day.ago

    response = nil
    expect {
      response = api.call(
        "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts"
      )
    }.to change {
      account.token
    }.and change {
      account.refresh_token
    }

    json = JSON.parse(response)

    graph = DfcIo.import(json)
    products = graph.select { |s| s.semanticType == "dfc-b:SuppliedProduct" }
    expect(products).to be_present
  end

  it "reports and raises server errors" do
    stub_request(:get, "http://example.net/api").to_return(status: 500)

    expect(Bugsnag).to receive(:notify)

    expect { api.call("http://example.net/api") }
      .to raise_error(Faraday::ServerError)
  end
end
