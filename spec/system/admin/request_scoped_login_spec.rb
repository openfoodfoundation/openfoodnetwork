# frozen_string_literal: true

require 'system_helper'
require 'net/http'

# Deterministic reproduction + proof for the request-scoped Warden login prototype.
#
# We simulate the flaky-spec root cause by firing a "stray" request straight at the
# Capybara test server (as if it had leaked from a previous example) so that it reaches
# Warden *after* `login_as` but *before* our own `visit`.
RSpec.describe "Request-scoped Warden test login" do
  include AuthenticationHelper

  # Fire a request at the app server through the same global Warden manager, with no
  # marker header — exactly what a request leaking from the previous example looks like.
  def fire_stray_request
    server = Capybara.current_session.server
    Net::HTTP.get_response(URI("http://#{server.host}:#{server.port}/admin"))
  end

  context "with the stock one-shot helper (no request scoping)" do
    it "reproduces the bug: the stray request steals the login" do
      login_as_admin
      fire_stray_request

      visit spree.edit_admin_tax_settings_path

      # The stray request consumed the queued login, so we land unauthenticated.
      expect(page).to have_no_css("body.admin")
    end
  end

  context "with request scoping", :request_scoped_login do
    it "keeps the login bound to our marked request" do
      login_as_admin
      fire_stray_request

      visit spree.edit_admin_tax_settings_path

      expect(page).to have_css("body.admin")
    end
  end
end
