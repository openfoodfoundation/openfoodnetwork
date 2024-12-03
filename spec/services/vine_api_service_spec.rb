# frozen_string_literal: true

require "spec_helper"

RSpec.describe VineApiService do
  subject(:vine_api) { described_class.new(api_key: vine_api_key, jwt_generator: jwt_service) }

  let(:vine_api_url) { "https://vine-staging.openfoodnetwork.org.au/api/v1" }
  let(:vine_api_key) { "12345" }
  let(:jwt_service) { VineJwtService.new(secret:) }
  let(:secret) { "my_secret" }
  let(:token) { "some.jwt.token" }

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

      expect_request_with_api_key(:get, "https://vine-staging.openfoodnetwork.org.au/api/v1/my-team")
    end

    it "sends JWT token via a header" do
      stub_request(:get, my_team_url).to_return(status: 200)
      mock_jwt_service

      vine_api.my_team

      expect_request_with_jwt_token(:get, "https://vine-staging.openfoodnetwork.org.au/api/v1/my-team")
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

        expect(Rails.logger).to receive(:error).with(match("VineApiService#my_team")).twice

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

  describe "#voucher_validation" do
    let(:voucher_validation_url) { "#{vine_api_url}/voucher-validation" }
    let(:voucher_short_code) { "123456" }
    # let(:voucher_short_code) { "CI3922" }

    it "send a POST request to the team VINE api endpoint" do
      stub_request(:post, voucher_validation_url).to_return(status: 200)
      vine_api.voucher_validation(voucher_short_code)

      expect(a_request(
        :post, "https://vine-staging.openfoodnetwork.org.au/api/v1/voucher-validation"
      ).with(body: { type: "voucher_code", value: voucher_short_code } )).to have_been_made
    end

    it "sends the VINE api key via a header" do
      stub_request(:post, voucher_validation_url).to_return(status: 200)

      vine_api.voucher_validation(voucher_short_code)

      expect_request_with_api_key(
        :post, "https://vine-staging.openfoodnetwork.org.au/api/v1/voucher-validation"
      )
    end

    it "sends JWT token via a header" do
      stub_request(:post, voucher_validation_url).to_return(status: 200)
      mock_jwt_service

      vine_api.voucher_validation(voucher_short_code)

      expect_request_with_jwt_token(
        :post, "https://vine-staging.openfoodnetwork.org.au/api/v1/voucher-validation"
      )
    end

    context "when a request succeed", :vcr do
      it "returns the response" do
        response = vine_api.voucher_validation(voucher_short_code)

        expect(response.success?).to be(true)
        expect(response.body).not_to be_empty
      end
    end

    context "when a request fails" do
      it "logs the error" do
        stub_request(:post, voucher_validation_url).to_return(body: "error", status: 401)

        expect(Rails.logger).to receive(:error).with(
          match("VineApiService#voucher_validation")
        ).twice

        response = vine_api.voucher_validation(voucher_short_code)

        expect(response.success?).to be(false)
      end

      it "return the response" do
        stub_request(:post, voucher_validation_url).to_return(body: "error", status: 401)
        response = vine_api.voucher_validation(voucher_short_code)

        expect(response.success?).to be(false)
        expect(response.body).not_to be_empty
      end
    end
  end

  def expect_request_with_api_key(method, url)
    expect(a_request(method, url).with( headers: { Authorization: "Bearer #{vine_api_key}" }))
      .to have_been_made
  end

  def expect_request_with_jwt_token(method, url)
    expect(a_request(method, url).with( headers: { 'X-Authorization': "JWT #{token}" }))
      .to have_been_made
  end

  def mock_jwt_service
    allow(jwt_service).to receive(:generate_token).and_return(token)
  end
end
