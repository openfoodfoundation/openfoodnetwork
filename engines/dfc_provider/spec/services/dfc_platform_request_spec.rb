# frozen_string_literal: true

require_relative "../spec_helper"

# These tests depend on valid OpenID Connect client credentials in your
# `.env.test.local` file if you want to update the VCR cassettes.
#
#     OPENID_APP_ID="..."
#     OPENID_APP_SECRET="..."
RSpec.describe DfcPlatformRequest do
  subject { DfcPlatformRequest.new(platform) }
  let(:platform) { "cqcm-dev" }

  it "receives an access token", :vcr do
    token = subject.request_token
    expect(token).to be_a String
    expect(token.length).to be > 20
  end
end
