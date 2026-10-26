# frozen_string_literal: true

RSpec.describe "OpenID Connect provider", feature: :oauth_provider do
  let(:user) { create(:user, email: "farmer@example.com") }
  let(:application) { create(:oauth_application) }
  let(:code_verifier) { "a" * 64 }
  let(:authorize_params) {
    {
      client_id: application.uid,
      redirect_uri: application.redirect_uri,
      response_type: "code",
      scope: "openid email",
      nonce: "n-0S6_WzA2Mj",
      code_challenge: Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier),
                                              padding: false),
      code_challenge_method: "S256",
    }
  }

  def log_in_with_ofn(application, params = authorize_params)
    post oauth_authorization_path, params: params.merge(client_id: application.uid)
    code = Rack::Utils.parse_query(URI(response.location).query).fetch("code")

    post oauth_token_path, params: {
      grant_type: "authorization_code", code:, redirect_uri: application.redirect_uri,
      client_id: application.uid, client_secret: application.secret, code_verifier:,
    }
    response.parsed_body
  end

  def verified_id_token(id_token, application)
    get oauth_discovery_keys_path
    jwks = response.parsed_body

    JWT.decode(
      id_token, nil, true,
      algorithms: ["RS256"], jwks:,
      iss: "http://test.host", verify_iss: true,
      aud: application.uid, verify_aud: true,
    ).first
  end

  describe "discovery" do
    it "uses the site URL for the issuer and every endpoint, whatever the host used" do
      host! "alias.test.host"

      get "/.well-known/openid-configuration"

      urls = response.parsed_body.slice("issuer", "authorization_endpoint", "token_endpoint",
                                        "userinfo_endpoint", "jwks_uri").values
      expect(urls).to all(start_with("http://test.host"))
    end

    it "publishes the provider configuration" do
      get "/.well-known/openid-configuration"

      expect(response).to have_http_status :ok
      expect(response.parsed_body).to include(
        "issuer" => "http://test.host",
        "authorization_endpoint" => "http://test.host/oauth/authorize",
        "token_endpoint" => "http://test.host/oauth/token",
        "userinfo_endpoint" => "http://test.host/oauth/userinfo",
        "jwks_uri" => "http://test.host/oauth/discovery/keys",
        "scopes_supported" => ["openid", "email"],
        "response_types_supported" => ["code"],
        "subject_types_supported" => ["pairwise"],
        "id_token_signing_alg_values_supported" => ["RS256"],
        "code_challenge_methods_supported" => ["S256"],
      )
    end

    it "publishes the public signing keys only" do
      get oauth_discovery_keys_path

      keys = response.parsed_body.fetch("keys")
      expect(keys.first).to include("kty" => "RSA", "alg" => "RS256", "use" => "sig")
      expect(keys.first.keys).not_to include "d", "p", "q"
    end
  end

  describe "ID token" do
    before { sign_in user }

    it "is signed and identifies the user to the application" do
      tokens = log_in_with_ofn(application)

      claims = verified_id_token(tokens.fetch("id_token"), application)
      expect(claims).to include(
        "nonce" => "n-0S6_WzA2Mj",
        "email" => "farmer@example.com",
        "email_verified" => true,
      )
      expect(claims["auth_time"]).to be_within(60).of(Time.zone.now.to_i)
    end

    it "keeps the time of the user's login, even after a refresh or another login" do
      login_time = Time.zone.now.change(usec: 0)
      tokens = log_in_with_ofn(application, authorize_params.merge(auth_time: 0))
      expect(verified_id_token(tokens["id_token"], application)["auth_time"])
        .to eq login_time.to_i

      travel 1.hour
      user.update!(current_sign_in_at: Time.zone.now)
      post oauth_token_path, params: {
        grant_type: "refresh_token", refresh_token: tokens["refresh_token"],
        client_id: application.uid, client_secret: application.secret,
      }

      expect(verified_id_token(response.parsed_body["id_token"], application)["auth_time"])
        .to eq login_time.to_i
    end

    it "gives each application its own stable identifier for the user" do
      other_application = create(:oauth_application)

      sub = verified_id_token(log_in_with_ofn(application)["id_token"], application)["sub"]
      same_app_sub = verified_id_token(log_in_with_ofn(application)["id_token"],
                                       application)["sub"]
      other_app_sub = verified_id_token(log_in_with_ofn(other_application)["id_token"],
                                        other_application)["sub"]

      expect(sub).to eq same_app_sub
      expect(sub).not_to eq other_app_sub
      expect(sub).to match(/\A\h{64}\z/)
    end

    it "derives the identifier from a dedicated secret" do
      sub = verified_id_token(log_in_with_ofn(application)["id_token"], application)["sub"]

      stub_const("ENV", ENV.to_h.merge("OIDC_PAIRWISE_SECRET" => "another secret"))
      other_sub = verified_id_token(log_in_with_ofn(application)["id_token"], application)["sub"]

      expect(other_sub).not_to eq sub
    end

    it "leaves the email out without the email scope" do
      tokens = log_in_with_ofn(application, authorize_params.merge(scope: "openid"))

      claims = verified_id_token(tokens.fetch("id_token"), application)
      expect(claims.keys).not_to include "email"
    end
  end

  describe "authentication prompts" do
    it "asks a logged in user to log in again with prompt=login" do
      sign_in user

      get oauth_authorization_path(authorize_params.merge(prompt: "login"))

      expect(response).to redirect_to(
        root_path(anchor: "/login", after_login: oauth_authorization_path(authorize_params))
      )

      get oauth_authorization_path(authorize_params)
      expect(response.location).to include "after_login="
    end

    it "asks to log in again when the login is older than max_age" do
      sign_in user
      get oauth_authorization_path(authorize_params.merge(max_age: 60))
      expect(response).to have_http_status :ok

      travel 10.minutes
      get oauth_authorization_path(authorize_params.merge(max_age: 60))

      expect(response).to have_http_status :redirect
      expect(response.location).to include "after_login="
    end

    it "doesn't count a remembered login as a fresh login for max_age" do
      post spree.spree_user_session_path, params: {
        spree_user: { email: user.email, password: user.password, remember_me: "1" }
      }
      cookies.delete("_h-ofn_session_id")
      get spree.account_path # logged in again by the remember me cookie
      expect(response).to have_http_status :ok

      get oauth_authorization_path(authorize_params.merge(max_age: 3600))

      expect(response).to have_http_status :redirect
      expect(response.location).to include "after_login="
    end

    it "returns login_required to the application with prompt=none and no session" do
      get oauth_authorization_path(authorize_params.merge(prompt: "none", state: "xyz"))

      redirect = URI(response.location)
      expect(redirect.to_s).to start_with application.redirect_uri
      expect(Rack::Utils.parse_query(redirect.query)).to include(
        "error" => "login_required", "state" => "xyz",
      )
    end
  end
end
