# frozen_string_literal: true

require "spec_helper"

describe Api::V0::ReportsController, type: :controller do
  let(:enterprise_user) { create(:user, enterprises: create(:enterprise)) }
  let(:params) {
    {
      report_type: 'packing',
      q: { created_at_lt: Time.zone.now }
    }
  }

  before do
    allow(controller).to receive(:spree_current_user) { current_user }
  end

  describe "fetching reports" do
    context "when the user is not authenticated" do
      let(:current_user) { nil }

      it "returns unauthorised response" do
        api_get :show, params

        assert_unauthorized!
      end
    end

    context "when the user has no enterprises" do
      let(:current_user) { create(:user) }

      it "returns unauthorised response" do
        api_get :show, params

        assert_unauthorized!
      end
    end

    context "when no report type is given" do
      let(:current_user) { enterprise_user }

      it "returns an error" do
        api_get :show, q: { example: 'test' }

        expect(response.status).to eq 422
        expect(json_response["error"]).to eq 'Please specify a report type'
      end
    end

    context "given a report type that doesn't exist" do
      let(:current_user) { enterprise_user }

      it "returns an error" do
        api_get :show, report_type: "xxxxxx", q: { example: 'test' }

        expect(response.status).to eq 422
        expect(json_response["error"]).to eq 'Report not found'
      end
    end

    context "with no query params provided" do
      let(:current_user) { enterprise_user }

      it "returns an error" do
        api_get :show, report_type: "packing"
        expect(response.status).to eq 422
        expect(json_response["error"]).to eq('Please supply Ransack search params in the request')
      end
    end
  end
end
