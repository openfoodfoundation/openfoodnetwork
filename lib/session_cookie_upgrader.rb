# frozen_string_literal: true

class SessionCookieUpgrader
  def initialize(app, options = {})
    @app = app
    @options = options
  end

  def call(env)
    request = ::Rack::Request.new(env)
    cookies = request.cookies
    old_key = @options[:old_key]
    new_key = @options[:new_key]

    # Set the session id for this request from the old session cookie (if present)
    # This must be done before @app.call(env) or a new session will be initialized
    cookies[new_key] = cookies[old_key] if cookies[old_key]

    status, headers, body = @app.call(env)

    if cookies[old_key]
      # Create new session cookie with pre-existing session id
      Rack::Utils.set_cookie_header!(
        headers,
        new_key,
        { value: cookies[old_key], path: "/", domain: @options[:domain] }
      )

      # Delete old session cookie
      Rack::Utils.delete_cookie_header!(headers, old_key)
    end

    [status, headers, body]
  end
end
