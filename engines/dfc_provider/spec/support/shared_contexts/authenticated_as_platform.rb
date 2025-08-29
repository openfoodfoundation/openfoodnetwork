# frozen_string_literal: true

# Authenticate via Authoriztion token
RSpec.shared_context "authenticated as platform" do
  let(:Authorization) {
    "Bearer #{file_fixture('startinblox_access_token.jwt').read}"
  }

  before do
    # Once upon a time when the access token hadn't expired yet...
    travel_to(Date.parse("2025-06-13"))

    # Reset any login via session cookie.
    login_as nil
  end
end
