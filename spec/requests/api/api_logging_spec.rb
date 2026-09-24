# frozen_string_literal: true

# Covers ApiLogger, the Rack middleware which records API usage in api_logs.
#
# These have to be request specs: controller specs bypass the Rack stack, so
# the middleware never runs in them.
RSpec.describe "API logging" do
  let(:user) { create(:user) }

  describe "a successful v0 request" do
    before { login_as user }

    it "records the request" do
      get "/api/v0/customers.json", headers: { "HTTP_USER_AGENT" => "curl/8.5.0" }

      expect(response).to have_http_status(:ok)

      log = ApiLog.last
      expect(log).to have_attributes(
        path: "/api/v0/customers.json",
        request_method: "GET",
        status: 200,
        user_id: user.id,
        user_agent: "curl/8.5.0",
        internal: false,
      )
    end
  end

  describe "a successful v1 request" do
    let(:enterprise) { create(:enterprise) }
    let(:api_token) { "a-token-for-the-enterprise-owner" }

    before { enterprise.owner.update!(spree_api_key: api_token) }

    it "records the user the token belongs to" do
      get "/api/v1/customers", headers: { "X-Api-Token" => api_token }

      expect(response).to have_http_status(:ok)
      expect(ApiLog.last).to have_attributes(
        path: "/api/v1/customers",
        request_method: "GET",
        status: 200,
        user_id: enterprise.owner.id,
      )
    end
  end

  describe "a successful DFC request" do
    before { login_as user }

    it "records the request under the mounted path" do
      get "/api/dfc/persons/#{user.id}"

      expect(response).to have_http_status(:ok)
      expect(ApiLog.last).to have_attributes(
        path: "/api/dfc/persons/#{user.id}",
        request_method: "GET",
        status: 200,
        user_id: user.id,
      )
    end
  end

  describe "error responses" do
    it "records an unauthorised request with no user" do
      get "/api/v1/customers", headers: { "X-Api-Token" => "not-a-real-key" }

      expect(response).to have_http_status(:unauthorized)
      expect(ApiLog.last).to have_attributes(status: 401, user_id: nil)
    end

    it "records a request for a route that doesn't exist" do
      get "/api/v0/no_such_endpoint"

      expect(response).to have_http_status(:not_found)
      expect(ApiLog.last).to have_attributes(
        path: "/api/v0/no_such_endpoint",
        status: 404,
      )
    end
  end

  describe "the recorded path" do
    it "never includes the query string, which can carry an API key" do
      get "/api/v0/customers.json?token=#{user.generate_api_key}"

      expect(ApiLog.last.path).to eq "/api/v0/customers.json"
      expect(ApiLog.pluck(:path).join).not_to include user.spree_api_key
    end
  end

  describe "requests that aren't logged" do
    it "ignores paths outside /api/" do
      expect { get "/" }.not_to change { ApiLog.count }
    end

    it "ignores the API docs, which sit at /api-docs" do
      expect { get "/api-docs/index.html" }.not_to change { ApiLog.count }
    end
  end

  describe "the internal flag" do
    before { login_as user }

    it "is set when the request comes from OFN's own front end" do
      get "/api/v0/customers.json", headers: { "HTTP_REFERER" => "http://#{host}/shops" }

      expect(ApiLog.last.internal).to be true
    end

    it "is not set when the request comes from somewhere else" do
      get "/api/v0/customers.json", headers: { "HTTP_ORIGIN" => "https://example.com" }

      expect(ApiLog.last.internal).to be false
    end

    it "is not set when a malformed Origin can't be parsed" do
      get "/api/v0/customers.json", headers: { "HTTP_ORIGIN" => "http://[not a uri" }

      expect(ApiLog.last.internal).to be false
    end
  end

  describe "hostile input" do
    before { login_as user }

    it "stores a user agent containing invalid UTF-8 without breaking the request" do
      get "/api/v0/customers.json", headers: { "HTTP_USER_AGENT" => "bad\xC3(\u0000agent" }

      expect(response).to have_http_status(:ok)
      expect(ApiLog.last.user_agent).to eq "bad(agent"
    end

    it "truncates an over-long user agent to the column limit" do
      get "/api/v0/customers.json", headers: { "HTTP_USER_AGENT" => "a" * 600 }

      expect(response).to have_http_status(:ok)
      expect(ApiLog.last.user_agent.length).to eq ApiLogger::USER_AGENT_LIMIT
    end
  end

  describe "a HEAD request" do
    before { login_as user }

    it "records the method as HEAD" do
      head "/api/v0/customers.json"

      expect(ApiLog.last.request_method).to eq "HEAD"
    end
  end
end
