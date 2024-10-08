# frozen_string_literal: true

require "spec_helper"

RSpec.describe VineApiService do
  subject(:vine_api) { described_class.new(api_key: vine_api_key, jwt_generator: jwt_service) }

  let(:vine_api_url) { "https://vine-staging.openfoodnetwork.org.au/api/v1" }
  let(:vine_api_key) { "12345" }
  let(:jwt_service) { VineJwtService.new(secret:) }
  let(:secret) { "my_secret" }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("VINE_API_URL").and_return(vine_api_url)
  end

  describe "#my_team" do
    let(:my_team_url) { "#{vine_api_url}/my-team" }

    it "send a request to the team VINE api endpoint" do
      stub_request(:get, my_team_url).to_return(status: 200)

      vine_api.my_team

      expect(a_request(
               :get, "https://vine-staging.openfoodnetwork.org.au/api/v1/my-team"
             )).to have_been_made
    end

    it "sends the VINE api key via a header" do
      stub_request(:get, my_team_url).to_return(status: 200)

      vine_api.my_team

      expect(a_request(:get, "https://vine-staging.openfoodnetwork.org.au/api/v1/my-team").with(
               headers: { Authorization: "Bearer #{vine_api_key}" }
             )).to have_been_made
    end

    it "sends JWT token via a header" do
      token = "some.jwt.token"
      stub_request(:get, my_team_url).to_return(status: 200)

      allow(jwt_service).to receive(:generate_token).and_return(token)

      vine_api.my_team

      expect(a_request(:get, "https://vine-staging.openfoodnetwork.org.au/api/v1/my-team").with(
               headers: { 'X-Authorization': "JWT #{token}" }
             )).to have_been_made
    end

    context "when a request succeed", :vcr do
      it "returns the response" do
        response = vine_api.my_team

        expect(response.success?).to be(true)
        expect(response.body).not_to be_empty
      end
    end

    context "when a request fails" do
      it "logs the error" do
        stub_request(:get, my_team_url).to_return(body: "error", status: 401)

        expect(Rails.logger).to receive(:error).twice

        response = vine_api.my_team

        expect(response.success?).to be(false)
      end

      it "return the response" do
        stub_request(:get, my_team_url).to_return(body: "error", status: 401)
        response = vine_api.my_team

        expect(response.success?).to be(false)
        expect(response.body).not_to be_empty
      end
    end
  end
end
