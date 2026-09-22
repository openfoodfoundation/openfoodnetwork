# frozen_string_literal: true

# Records every API request in the api_logs table so that API usage can be
# reported on in Metabase.
#
# This is Rack middleware rather than a controller callback because the three
# API stacks have little in common: Api::V0::BaseController inherits from
# ActionController::Metal and so emits no ActionController instrumentation at
# all, and all three use `rescue_from` handlers and authentication filters that
# halt the callback chain. An `after_action` would therefore miss exactly the
# error responses we want to record.
#
# The authenticated user can only be resolved by the controllers (each API
# version uses a different token header), so they leave it in env[USER_ID_KEY].
class ApiLogger
  # Matches /api/v0, /api/v1 and the DFC engine mounts (/api/dfc,
  # /api/dfc-v1.6, /api/dfc-v1.7). Anchored so that /api-docs is excluded.
  API_PATH = %r{\A/api/}

  USER_ID_KEY = "ofn.api_user_id"

  PATH_LIMIT = 255
  USER_AGENT_LIMIT = 512

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ::Rack::Request.new(env)

    return @app.call(env) unless API_PATH.match?(request.path)

    # Read the request details up front. Middleware and controllers further
    # down the stack may rewrite the path while rendering an error response.
    details = request_details(request)

    begin
      response = @app.call(env)
    rescue Exception => e # rubocop:disable Lint/RescueException
      # Rack::Timeout::RequestTimeoutException inherits from Exception, not
      # StandardError, so that apps can't accidentally swallow it. We only
      # observe the status here and always re-raise.
      log(details, status_for(e), env)
      raise
    end

    log(details, response.first, env)

    response
  end

  private

  def request_details(request)
    {
      # request.path excludes the query string on purpose: the v0 and v1 APIs
      # both accept ?token=<api key>, which must not be persisted in plain text.
      path: clean(request.path, PATH_LIMIT),
      request_method: clean(request.request_method, 10),
      user_agent: clean(request.user_agent, USER_AGENT_LIMIT),
      internal: internal?(request),
    }
  end

  # Was the request made by OFN's own front end rather than by an API client?
  # The Darkswarm shopfront and the AngularJS admin call /api/v0 on almost
  # every page, and that traffic would otherwise drown out real API usage.
  def internal?(request)
    source = request.get_header("HTTP_ORIGIN").presence || request.referer.presence

    return false if source.blank?

    URI.parse(source).host == request.host
  rescue URI::Error
    false
  end

  # Request strings may contain invalid UTF-8 or null bytes, which PostgreSQL
  # rejects. A failed insert would abort the surrounding transaction, taking
  # the whole request with it, so we scrub before writing rather than rely on
  # the rescue in #log.
  def clean(value, limit)
    value.to_s.dup.force_encoding(Encoding::UTF_8).scrub("").delete("\u0000").truncate(limit)
  end

  def status_for(exception)
    ActionDispatch::ExceptionWrapper.status_code_for_exception(exception.class.name)
  end

  def log(details, status, env)
    ApiLog.create!(**details, status:, user_id: env[USER_ID_KEY])
  rescue StandardError => e
    # Logging must never break an API request. We don't report this to Bugsnag:
    # whatever makes the insert fail is likely to affect every request.
    Rails.logger.error("ApiLogger failed to record a request: #{e.class}: #{e.message}")
  end
end
