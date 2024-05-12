# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcRequest do
  subject(:api) { DfcRequest.new(user) }

  let(:user) { build(:oidc_user) }
  let(:account) { user.oidc_account }

  it "gets a DFC document" do
    stub_request(:get, "http://example.net/api").
      to_return(status: 200, body: '{"@context":"/"}')

    expect(api.get("http://example.net/api")).to eq '{"@context":"/"}'
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

    expect {
      api.get("http://example.net/api")
    }.to change {
      account.token
    }.and change {
      account.refresh_token
    }
  end

  it "doesn't try to refresh the token when it's still fresh" do
    stub_request(:get, "http://example.net/api").
      to_return(status: 401)

    user.oidc_account.updated_at = 1.minute.ago

    expect(api.get("http://example.net/api")).to eq ""

    # Trying to reach the OIDC server via network request to refresh the token
    # would raise errors because we didn't setup Webmock or VCR.
    # The absence of errors makes this test pass.
  end
end
