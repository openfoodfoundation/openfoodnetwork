# frozen_string_literal: true

RSpec.describe ConnectedApps::Vine do
  subject(:connected_app) { ConnectedApps::Vine.new(enterprise: create(:enterprise)) }

  let(:vine_api_key) { "12345" }
  let(:secret) { "my_secret" }
  let(:vine_api) { instance_double(Vine::ApiService) }

  describe "#connect" do
    it "send a request to VINE api" do
      expect(vine_api).to receive(:my_team).and_return(mock_api_response(true))

      connected_app.connect(api_key: vine_api_key, secret:, vine_api: )
    end

    context "when request succeed" do
      it "store the vine api key and secret" do
        allow(vine_api).to receive(:my_team).and_return(mock_api_response(true))

        expect(connected_app.connect(api_key: vine_api_key, secret:, vine_api:)).to eq(true)
        expect(connected_app.data).to eql({ "api_key" => vine_api_key, "secret" => secret })
      end
    end

    context "when request fails" do
      it "doesn't store the vine api key" do
        allow(vine_api).to receive(:my_team).and_return(mock_api_response(false))

        expect(connected_app.connect(api_key: vine_api_key, secret:, vine_api:)).to eq(false)
        expect(connected_app.data).to be_nil
        expect(connected_app.errors[:base]).to include(
          "An error occured when connecting to Vine API"
        )
      end
    end
  end

  def mock_api_response(success)
    mock_response = instance_double(Faraday::Response)
    allow(mock_response).to receive(:success?).and_return(success)
    mock_response
  end
end
