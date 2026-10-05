# frozen_string_literal: true

RSpec.describe "OAuth2 provider", feature: :oauth_provider do
  let(:user) { create(:user, email: "farmer@example.com") }
  let(:application) { create(:oauth_application) }
  let(:code_verifier) { "a" * 64 }
  let(:code_challenge) {
    Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
  }
  let(:authorize_params) {
    {
      client_id: application.uid,
      redirect_uri: application.redirect_uri,
      response_type: "code",
      scope: "profile",
      state: "xyz",
      code_challenge:,
      code_challenge_method: "S256",
    }
  }

  describe "GET /oauth/authorize" do
    it "asks a guest to log in, then come back" do
      get oauth_authorization_path(authorize_params)

      expect(response).to redirect_to(
        root_path(anchor: "/login", after_login: request.fullpath)
      )
    end

    it "comes back to the authorization after logging in" do
      get oauth_authorization_path(authorize_params)
      follow_redirect!

      post spree.spree_user_session_path, params: {
        spree_user: { email: user.email, password: user.password }
      }

      expect(response).to redirect_to oauth_authorization_path(authorize_params)
    end

    it "requires PKCE from a public application" do
      application.update!(confidential: false)
      sign_in user

      get oauth_authorization_path(authorize_params.except(:code_challenge, :code_challenge_method))

      expect(response).to have_http_status :bad_request
    end

    it "asks a logged in user to approve the application" do
      sign_in user

      get oauth_authorization_path(authorize_params)

      expect(response).to have_http_status :ok
      expect(response.body).to include application.name
    end

    it "shows the OFN instance branding, the account and where the user goes next" do
      Spree::Config[:site_name] = "Coop Market"
      sign_in user

      get oauth_authorization_path(authorize_params)

      expect(response.body).to include(
        "Coop Market", ContentConfig.url_for(:logo), user.email, "app.example.com"
      )
    end

    it "doesn't authorize a disabled user" do
      user.update!(disabled_at: Time.zone.now)
      sign_in user

      get oauth_authorization_path(authorize_params)

      expect(response).to redirect_to(root_path(anchor: "/login", after_login: request.fullpath))
    end
  end

  describe "authorization code flow" do
    before { sign_in user }

    def authorize_and_get_code
      post oauth_authorization_path, params: authorize_params
      expect(response).to have_http_status :redirect

      redirect = URI(response.location)
      expect(redirect.to_s).to start_with application.redirect_uri
      query = Rack::Utils.parse_query(redirect.query)
      expect(query["state"]).to eq "xyz"
      query.fetch("code")
    end

    def exchange_code(code, verifier: code_verifier)
      post oauth_token_path, params: {
        grant_type: "authorization_code",
        code:,
        redirect_uri: application.redirect_uri,
        client_id: application.uid,
        client_secret: application.secret,
        code_verifier: verifier,
      }
    end

    it "gives an access token identifying the user" do
      exchange_code(authorize_and_get_code)

      expect(response).to have_http_status :ok
      access_token = response.parsed_body.fetch("access_token")
      expect(response.parsed_body["refresh_token"]).to be_present

      get oauth_userinfo_path, headers: { "Authorization" => "Bearer #{access_token}" }

      expect(response).to have_http_status :ok
      expect(response.parsed_body).to eq(
        "sub" => user.id.to_s,
        "email" => "farmer@example.com",
      )
    end

    it "rejects a wrong PKCE code verifier" do
      exchange_code(authorize_and_get_code, verifier: "b" * 64)

      expect(response).to have_http_status :bad_request
      expect(response.parsed_body["error"]).to eq "invalid_grant"
    end
  end

  describe "GET /oauth/userinfo" do
    let(:token) {
      Doorkeeper::AccessToken.create!(application:, resource_owner_id: user.id, scopes: "profile")
    }

    def get_userinfo(token)
      get oauth_userinfo_path, headers: { "Authorization" => "Bearer #{token}" }
    end

    it "rejects a request without token" do
      get oauth_userinfo_path

      expect(response).to have_http_status :unauthorized
    end

    it "rejects a revoked token" do
      token.revoke

      get_userinfo(token.plaintext_token)

      expect(response).to have_http_status :unauthorized
    end

    it "rejects a token of a user disabled since" do
      plaintext_token = token.plaintext_token
      user.update!(disabled: "1")

      get_userinfo(plaintext_token)

      expect(response).to have_http_status :unauthorized
    end
  end
end
