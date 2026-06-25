# frozen_string_literal: true

# PROTOTYPE — opt in per example with `:request_scoped_login` metadata.
#
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
# Fix: tag the example's own request with a marker HTTP header and only apply the queued
# login to a request carrying that header. A leaked request can't carry it — Chrome cannot
# retro-add a header (`Network.setExtraHTTPHeaders`) to an already-dispatched request — so
# it can no longer steal the login. One-shot semantics are preserved: the login is applied
# exactly once, then the session cookie carries it, so logout / forbidden-redirect still work.
module RequestScopedLogin
  HEADER = "X-Warden-Test-Login"
  ENV_KEY = "HTTP_X_WARDEN_TEST_LOGIN"

  # One-shot holder, mirrors Warden._on_next_request but drained only by the marked request.
  def self.pending
    @pending ||= []
  end

  def self.install_warden_hook!
    return if @installed

    Warden::Manager.on_request do |proxy|
      next unless proxy.env[ENV_KEY]

      while (entry = pending.shift)
        user, opts = entry
        proxy.set_user(user, opts)
      end
    end
    @installed = true
  end

  # Overrides Warden::Test::Helpers#login_as for tagged examples.
  def login_as(user, opts = {})
    opts = { event: :authentication }.merge(opts)
    RequestScopedLogin.pending.replace([[user, opts]])
    page.driver.add_header(RequestScopedLogin::HEADER, "1")
  end
end

RequestScopedLogin.install_warden_hook!

RSpec.configure do |config|
  config.prepend RequestScopedLogin, request_scoped_login: true
  config.after(:each, request_scoped_login: true) { RequestScopedLogin.pending.clear }
end
