# frozen_string_literal: true

require 'system_helper'
require 'net/http'

# Regression guard for request-scoped Warden test login (see
# spec/system/support/request_scoped_login.rb). We reproduce the flaky-spec root cause by
# firing a "stray" request straight at the Capybara test server — as if it had leaked from a
# previous example — so that it reaches Warden *after* `login_as` but *before* our `visit`.
# Without request scoping that stray request consumes the queued login and we land
# unauthenticated; with it, the login stays bound to our own (token-marked) request.
RSpec.describe "Request-scoped Warden test login" do
  include AuthenticationHelper

  def fire_stray_request(headers = {})
    server = Capybara.current_session.server
    uri = URI("http://#{server.host}:#{server.port}/admin")
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new(uri)
      headers.each { |name, value| request[name] = value }
      http.request(request)
    end
  end

  it "keeps the login bound to our request even if a stray request reaches Warden first" do
    login_as_admin

    # A request with no marker header, exactly like one leaking from an example that never
    # logged in.
    fire_stray_request

    visit spree.edit_admin_tax_settings_path

    expect(page).to have_css("body.admin")
  end

  it "is not stolen by a stray request carrying a previous example's marker token" do
    login_as_admin

    # A leak from a *previous logged-in* example carries a marker header, but with that
    # example's own (now stale) token value — never our fresh one.
    fire_stray_request(RequestScopedLogin::HEADER => "stale-token-from-previous-example")

    visit spree.edit_admin_tax_settings_path

    expect(page).to have_css("body.admin")
  end
end
