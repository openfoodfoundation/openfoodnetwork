# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe OidcRequest do
  subject(:api) { OidcRequest.new("some-token") }

  it "gets a DFC document" do
    stub_request(:get, "http://example.net/api").
      to_return(status: 200, body: '{"@context":"/"}')

    expect(api.call("http://example.net/api").body).to eq '{"@context":"/"}'
  end

  it "posts a DFC document" do
    json = '{"name":"new season apples"}'
    stub_request(:post, "http://example.net/api").
      with(body: json).
      to_return(status: 201) # Created

    expect(api.call("http://example.net/api", json).body).to eq ""
  end

  it "reports and raises server errors" do
    stub_request(:get, "http://example.net/api").to_return(status: 500)

    expect(Bugsnag).to receive(:notify)

    expect { api.call("http://example.net/api") }
      .to raise_error(Faraday::ServerError)
  end
end
