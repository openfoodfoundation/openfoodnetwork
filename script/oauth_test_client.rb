# frozen_string_literal: true

# Minimal OpenID Connect client to try the OFN provider by hand. Ruby stdlib only.
#
#   0. Enable the oauth_provider feature in /admin/feature-toggle.
#   1. In OFN admin, Configuration > OAuth applications, create an application
#      with redirect URI http://localhost:8000/callback (keep "Confidential").
#   2. CLIENT_ID=... CLIENT_SECRET=... ruby script/oauth_test_client.rb
#   3. Open http://localhost:8000
#
# OFN_URL defaults to http://localhost:3000. Endpoints are read from the OpenID
# Connect discovery document, and the ID token is checked like a real client
# would: signature against the published keys, issuer, audience, nonce, expiry.

require "webrick"
require "net/http"
require "json"
require "securerandom"
require "digest"
require "base64"
require "openssl"
require "cgi"

OFN_URL = ENV.fetch("OFN_URL", "http://localhost:3000")
CLIENT_ID = ENV.fetch("CLIENT_ID")
CLIENT_SECRET = ENV.fetch("CLIENT_SECRET")
REDIRECT_URI = "http://localhost:8000/callback"

def http_get(url, headers = {})
  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.request(Net::HTTP::Get.new(uri, headers))
  end
end

DISCOVERY = JSON.parse(http_get("#{OFN_URL}/.well-known/openid-configuration").body)

pending = {} # state => { verifier:, nonce: }
session = {} # last token response

def page(body)
  "<!doctype html><meta charset=utf-8><title>OIDC test client</title>" \
    "<body style='font-family:sans-serif;max-width:720px;margin:2em auto'>" \
    "<h1>OIDC test client</h1>#{body}<p><a href='/'>Start again</a></p>"
end

def show(title, data)
  "<h2>#{title}</h2><pre>#{CGI.escapeHTML(JSON.pretty_generate(data))}</pre>"
end

def token_request(params)
  response = Net::HTTP.post_form(
    URI(DISCOVERY["token_endpoint"]),
    params.merge(client_id: CLIENT_ID, client_secret: CLIENT_SECRET)
  )
  [response.code, JSON.parse(response.body)]
end

def userinfo(access_token)
  response = http_get(DISCOVERY["userinfo_endpoint"], "Authorization" => "Bearer #{access_token}")
  { status: response.code, body: response.body.empty? ? nil : JSON.parse(response.body) }
end

# Builds an RSA public key from its JWK modulus and exponent.
def rsa_public_key(jwk)
  modulus, exponent = jwk.values_at("n", "e").map do |value|
    OpenSSL::ASN1::Integer(OpenSSL::BN.new(Base64.urlsafe_decode64(value), 2))
  end
  algorithm = OpenSSL::ASN1::Sequence([OpenSSL::ASN1::ObjectId("rsaEncryption"),
                                       OpenSSL::ASN1::Null(nil)])
  key = OpenSSL::ASN1::BitString(OpenSSL::ASN1::Sequence([modulus, exponent]).to_der)
  OpenSSL::PKey::RSA.new(OpenSSL::ASN1::Sequence([algorithm, key]).to_der)
end

def check_id_token(id_token, nonce)
  header, payload, signature = id_token.split(".")
  kid = JSON.parse(Base64.urlsafe_decode64(header))["kid"]
  claims = JSON.parse(Base64.urlsafe_decode64(payload))
  jwks = JSON.parse(http_get(DISCOVERY["jwks_uri"]).body)["keys"]
  jwk = jwks.find { |key| key["kid"] == kid }

  {
    claims:,
    checks: {
      signature: !!jwk && rsa_public_key(jwk).verify("SHA256", Base64.urlsafe_decode64(signature),
                                                     "#{header}.#{payload}"),
      issuer: claims["iss"] == DISCOVERY["issuer"],
      audience: claims["aud"] == CLIENT_ID,
      nonce: nonce.nil? || claims["nonce"] == nonce,
      not_expired: claims["exp"].to_i > Time.now.to_i,
    }
  }
end

def token_result(status, tokens, nonce: nil)
  result = show("Token response (HTTP #{status})", tokens)
  result += show("ID token", check_id_token(tokens["id_token"], nonce)) if tokens["id_token"]
  return result unless tokens["access_token"]

  "#{result}#{show('User info', userinfo(tokens['access_token']))}" \
    "<form method=post action=/refresh><button>Refresh the token</button></form>"
end

server = WEBrick::HTTPServer.new(Port: 8000, BindAddress: "localhost")

server.mount_proc "/" do |_req, res|
  state = SecureRandom.hex(16)
  pending[state] = { verifier: SecureRandom.urlsafe_base64(48), nonce: SecureRandom.hex(16) }
  query = URI.encode_www_form(
    client_id: CLIENT_ID, redirect_uri: REDIRECT_URI, response_type: "code",
    scope: "openid email", state:, nonce: pending[state][:nonce],
    code_challenge: Base64.urlsafe_encode64(Digest::SHA256.digest(pending[state][:verifier]),
                                            padding: false),
    code_challenge_method: "S256"
  )
  res.content_type = "text/html"
  res.body = page("<p><a href='#{DISCOVERY['authorization_endpoint']}?#{query}'>" \
                  "Log in with OFN</a></p>")
end

server.mount_proc "/callback" do |req, res|
  res.content_type = "text/html"
  request = pending.delete(req.query["state"])

  res.body = if req.query["error"]
               page(show("Authorization refused", req.query))
             elsif request.nil?
               page("<p>Unknown state: start again.</p>")
             else
               status, tokens = token_request(
                 grant_type: "authorization_code", code: req.query["code"],
                 redirect_uri: REDIRECT_URI, code_verifier: request[:verifier]
               )
               session.replace(tokens)
               page(token_result(status, tokens, nonce: request[:nonce]))
             end
end

server.mount_proc "/refresh" do |_req, res|
  status, tokens = token_request(grant_type: "refresh_token",
                                 refresh_token: session["refresh_token"])
  session.replace(tokens) if tokens["access_token"]
  res.content_type = "text/html"
  res.body = page(token_result(status, tokens))
end

trap("INT") { server.shutdown }
puts "OIDC test client on http://localhost:8000 (OFN: #{OFN_URL})"
server.start
