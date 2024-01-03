# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConnectAppJob, type: :job do
  subject { ConnectAppJob.new(app, user.spree_api_key) }

  let(:app) { ConnectedApp.new(enterprise: ) }
  let(:enterprise) { build(:enterprise, id: 3, owner: user) }
  let(:user) { build(:user, spree_api_key: "12345") }
  let(:url) { "https://n8n.openfoodnetwork.org.uk/webhook/regen/connect-enterprise" }

  it "sends a semantic id and access token" do
    stub_request(:post, url).to_return(body: '{}')

    subject.perform_now

    request = a_request(:post, url).with(
      body: hash_including(
        {
          data: {
            '@id': "http://test.host/api/dfc/enterprises/3",
            access_token: "12345",
          }
        }
      )
    )
    expect(request).to have_been_made.once
  end

  it "stores connection data on the app", vcr: true do
    subject.perform_now

    expect(app.data).to eq(
      {
        "link" => "https://example.net/update",
        "destroy" => "https://n8n.openfoodnetwork.org.uk/webhook/remove-enterprise?id=recjBXXXXXXXXXXXX&key=12345",
      }
    )
  end
end
