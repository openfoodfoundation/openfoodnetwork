# frozen_string_literal: true

# Authenticate via Authoriztion token
RSpec.shared_context "authenticated as platform" do
  let(:Authorization) {
    "Bearer #{file_fixture('startinblox_access_token.jwt').read}"
  }

  around do |example|
    # Once upon a time when the access token hadn't expired yet...
    Timecop.travel(Date.parse("2025-06-13")) { example.run }
  end

  # Reset any login via session cookie.
  before { login_as nil }
end
