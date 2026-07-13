# frozen_string_literal: true

require "securerandom"

# Binds Warden's test login to the specific request the example makes, instead of
# "the next request to reach Warden".
#
# Background: `Warden::Test::Helpers#login_as` queues a one-shot block on the global
# `Warden._on_next_request`, and Warden's test-mode hook drains that queue on the FIRST
# non-asset request to reach Warden. With the Cuprite/JS driver a request can leak from
# the previous example (an XHR the browser dispatched before Capybara reset the session),
# reach Warden after our `before { login_as }` but before our `visit`, consume the queued
# login against its own throw-away session, and leave the real page unauthenticated and
# redirected to the public login screen. See teamcapybara/capybara#702 and #1692.
#
# Fix: tag the example's own request with a marker HTTP header whose value is a fresh,
# per-`login_as` token, and apply the queued login only to a request carrying THAT token.
# A leaked request cannot carry it:
# - a request from a previous example carries that example's (now stale) token, and
# - Chrome cannot retro-add a header (`Network.setExtraHTTPHeaders`) to an already-dispatched
#   request,
# so a leak can never match the current example's token and can no longer steal the login.
# Using a constant marker value is not enough: every logged-in example sets the same header,
# so a leak from the previous logged-in example carries it and still races us (this is why
# the earlier constant-value version stayed flaky).
#
# One-shot semantics are preserved: the login is keyed by token and deleted on first use, then
# the session cookie carries it, so logout / forbidden-redirect still work.
#
# Applied to every system spec; the Warden hook is token-gated, so examples that never call
# `login_as` are unaffected (no header is set, so no request carries a known token and the
# hook no-ops).
module RequestScopedLogin
  HEADER = "X-Warden-Test-Login"
  ENV_KEY = "HTTP_X_WARDEN_TEST_LOGIN"

  # One-shot logins keyed by token; each is drained only by a request carrying its token.
  def self.pending
    @pending ||= {}
  end

  def self.install_warden_hook!
    return if @installed

    Warden::Manager.on_request do |proxy|
      token = proxy.env[ENV_KEY]
      next unless token

      entry = pending.delete(token)
      next unless entry

      user, opts = entry
      proxy.set_user(user, opts)
    end
    @installed = true
  end

  # Overrides Warden::Test::Helpers#login_as for system specs.
  def login_as(user, opts = {})
    opts = { event: :authentication }.merge(opts)
    token = SecureRandom.hex(16)
    RequestScopedLogin.pending[token] = [user, opts]
    page.driver.add_header(RequestScopedLogin::HEADER, token)
  end
end

RequestScopedLogin.install_warden_hook!

RSpec.configure do |config|
  config.prepend RequestScopedLogin, type: :system
  config.after(:each, type: :system) { RequestScopedLogin.pending.clear }
end
