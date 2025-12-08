# frozen_string_literal: true

# Authenticate via Authoriztion token
RSpec.shared_context "authenticated as platform" do
  let(:Authorization) {
    "Bearer #{access_token}"
  }
  let(:access_token) {
    file_fixture("startinblox_access_token.jwt").read
  }

  before do
    payload = JWT.decode(access_token, nil, false, { algorithm: "RS256" }).first
    issued_at = Time.zone.at(payload["iat"])

    # Once upon a time when the access token hadn't expired yet...
    travel_to(issued_at)

    # Reset any login via session cookie.
    login_as nil
  end
end
