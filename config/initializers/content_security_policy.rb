# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src :self, :https, :data, "fonts.gstatic.com"
  policy.img_src :self, :https, :data, ENV.fetch("S3_CORS_POLICY_DOMAIN", "*.s3.amazonaws.com")
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

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
