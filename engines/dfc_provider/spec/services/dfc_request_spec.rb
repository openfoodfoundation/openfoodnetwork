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

    expect {
      api.call("http://example.net/api")
    }
      .to raise_error(Faraday::UnauthorizedError)
      .and change {
             account.token
           }.and change {
                   account.refresh_token
                 }
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

  describe "refreshing token when stale" do
    before do
      account.uid = "testdfc@protonmail.com"
      account.refresh_token = ENV.fetch("OPENID_REFRESH_TOKEN")
      account.updated_at = 1.day.ago
    end

    it "refreshes the access token and retrieves the FDC catalog", vcr: true do
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

    context "with account tokens" do
      before do
        account.refresh_token = ENV.fetch("OPENID_REFRESH_TOKEN")
        api.call(
          "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts"
        )
        expect(account.token).not_to be_nil
      end

      it "clears the token if authentication fails", vcr: true do
        allow_any_instance_of(OpenIDConnect::Client).to receive(:access_token!).and_raise(
          Rack::OAuth2::Client::Error.new(
            1, { error: "invalid_grant", error_description: "session not active" }
          )
        )

        expect {
          api.call(
            "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts"
          )
        }.to raise_error(Rack::OAuth2::Client::Error).and change {
          account.token
        }.to(nil).and change {
          account.refresh_token
        }.to(nil)
      end
    end
  end
end
