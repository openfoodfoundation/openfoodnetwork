# frozen_string_literal: true

require 'system_helper'
require 'net/http'

# Regression guard for request-scoped Warden test login (see
# spec/system/support/request_scoped_login.rb). We reproduce the flaky-spec root cause by
# firing a "stray" request straight at the Capybara test server — as if it had leaked from a
# previous example — so that it reaches Warden *after* `login_as` but *before* our `visit`.
# Without request scoping that stray request consumes the queued login and we land
# unauthenticated; with it, the login stays bound to our own (header-marked) request.
RSpec.describe "Request-scoped Warden test login" do
  include AuthenticationHelper

  it "keeps the login bound to our request even if a stray request reaches Warden first" do
    login_as_admin

    # A request with no marker header, exactly like one leaking from the previous example.
    server = Capybara.current_session.server
    Net::HTTP.get_response(URI("http://#{server.host}:#{server.port}/admin"))

    visit spree.edit_admin_tax_settings_path

    expect(page).to have_css("body.admin")
  end
end
