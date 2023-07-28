# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src :self, :https, :data, "fonts.gstatic.com"
  policy.img_src :self, :https, :data, "*.s3.amazonaws.com"
  policy.img_src :self, :http, :data, ENV["SITE_URL"] if Rails.env.development?
  policy.object_src :none
  policy.frame_ancestors :none
  policy.script_src :self, :https, :unsafe_inline, :unsafe_eval, "*.stripe.com", "openfoodnetwork.innocraft.cloud",
                    "maps.googleapis.com", "maps.gstatic.com", "d2wy8f7a9ursnm.cloudfront.net"
  policy.style_src :self, :https, :unsafe_inline, "fonts.googleapis.com", "cdnjs.cloudflare.com"

  if Rails.env.development?
    policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035", "ws://localhost:3000"
  else
    policy.connect_src :self, :https, "https://#{ENV["SITE_URL"]}", "wss://#{ENV["SITE_URL"]}"
  end

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
