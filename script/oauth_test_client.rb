# frozen_string_literal: true

# Minimal OAuth2 client to try the OFN provider by hand. Ruby stdlib only.
#
#   0. Enable the oauth_provider feature in /admin/feature-toggle.
#   1. In OFN admin, Configuration > OAuth applications, create an application
#      with redirect URI http://localhost:8000/callback (keep "Confidential").
#   2. CLIENT_ID=... CLIENT_SECRET=... ruby script/oauth_test_client.rb
#   3. Open http://localhost:8000
#
# OFN_URL defaults to http://localhost:3000.

require "webrick"
require "net/http"
require "json"
require "securerandom"
require "digest"
require "base64"
require "cgi"

OFN_URL = ENV.fetch("OFN_URL", "http://localhost:3000")
CLIENT_ID = ENV.fetch("CLIENT_ID")
CLIENT_SECRET = ENV.fetch("CLIENT_SECRET")
REDIRECT_URI = "http://localhost:8000/callback"

pending = {} # state => PKCE code verifier
session = {} # last token response

def page(body)
  "<!doctype html><meta charset=utf-8><title>OAuth test client</title>" \
    "<body style='font-family:sans-serif;max-width:720px;margin:2em auto'>" \
    "<h1>OAuth test client</h1>#{body}<p><a href='/'>Start again</a></p>"
end

def show(title, data)
  "<h2>#{title}</h2><pre>#{CGI.escapeHTML(JSON.pretty_generate(data))}</pre>"
end

def token_request(params)
  response = Net::HTTP.post_form(
    URI("#{OFN_URL}/oauth/token"),
    params.merge(client_id: CLIENT_ID, client_secret: CLIENT_SECRET)
  )
  [response.code, JSON.parse(response.body)]
end

def userinfo(access_token)
  uri = URI("#{OFN_URL}/oauth/userinfo")
  request = Net::HTTP::Get.new(uri, "Authorization" => "Bearer #{access_token}")
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.request(request)
  end
  { status: response.code, body: response.body.empty? ? nil : JSON.parse(response.body) }
end

def tokens_and_userinfo(status, tokens)
  result = show("Token response (HTTP #{status})", tokens)
  return result unless tokens["access_token"]

  "#{result}#{show('GET /oauth/userinfo', userinfo(tokens['access_token']))}" \
    "<form method=post action=/refresh><button>Refresh the token</button></form>"
end

server = WEBrick::HTTPServer.new(Port: 8000, BindAddress: "localhost")

server.mount_proc "/" do |_req, res|
  state = SecureRandom.hex(16)
  verifier = SecureRandom.urlsafe_base64(48)
  pending[state] = verifier
  query = URI.encode_www_form(
    client_id: CLIENT_ID, redirect_uri: REDIRECT_URI, response_type: "code",
    scope: "profile", state:,
    code_challenge: Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false),
    code_challenge_method: "S256"
  )
  res.content_type = "text/html"
  res.body = page("<p><a href='#{OFN_URL}/oauth/authorize?#{query}'>Log in with OFN</a></p>")
end

server.mount_proc "/callback" do |req, res|
  res.content_type = "text/html"
  verifier = pending.delete(req.query["state"])

  res.body = if req.query["error"]
               page(show("Authorization refused", req.query))
             elsif verifier.nil?
               page("<p>Unknown state: start again.</p>")
             else
               status, tokens = token_request(
                 grant_type: "authorization_code", code: req.query["code"],
                 redirect_uri: REDIRECT_URI, code_verifier: verifier
               )
               session.replace(tokens)
               page(tokens_and_userinfo(status, tokens))
             end
end

server.mount_proc "/refresh" do |_req, res|
  status, tokens = token_request(grant_type: "refresh_token",
                                 refresh_token: session["refresh_token"])
  session.replace(tokens) if tokens["access_token"]
  res.content_type = "text/html"
  res.body = page(tokens_and_userinfo(status, tokens))
end

trap("INT") { server.shutdown }
puts "OAuth test client on http://localhost:8000 (OFN: #{OFN_URL})"
server.start
