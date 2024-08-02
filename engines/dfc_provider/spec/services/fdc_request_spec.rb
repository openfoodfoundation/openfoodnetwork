# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe FdcRequest do
  subject(:api) { FdcRequest.new(user) }

  let(:user) { build(:oidc_user) }
  let(:account) { user.oidc_account }
  let(:url) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts"
  }

  it "refreshes the access token and retrieves a catalog", vcr: true do
    # A refresh is only attempted if the token is stale.
    account.uid = "testdfc@protonmail.com"
    account.refresh_token = ENV.fetch("OPENID_REFRESH_TOKEN")
    account.updated_at = 1.day.ago

    response = nil
    expect {
      response = api.call(url)
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
end
