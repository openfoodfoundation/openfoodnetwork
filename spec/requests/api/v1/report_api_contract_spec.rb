# frozen_string_literal: true

require "swagger_helper"
require "uri"

RSpec.describe "Report API contract", swagger_doc: "v1.yaml" do
  let!(:distributor) { create(:distributor_enterprise) }

  let(:rows) do
    (1..205).map { |number| { "row_number" => number } }
  end

  let(:report) do
    instance_double(
      Reporting::Reports::Packing::Customer,
      as_json: rows
    )
  end

  before do
    allow(Reporting::Reports::Packing::Customer).
      to receive(:new).and_return(report)
  end

  def expect_api_error(status)
    expect(response).to have_http_status(status)
    expect(json_response[:errors]).to include(
      include(detail: kind_of(String))
    )
    expect(json_response).not_to have_key(:data)
  end

  describe "pagination" do
    before do
      login_as distributor.owner
    end

    it "defaults to the first 50 rows and reports the full row count" do
      get "/api/v1/reports/packing",
          params: { distributor_id: distributor.id }

      expect(response).to have_http_status(:ok)
      expect(json_response[:data].pluck(:row_number)).
        to eq((1..50).to_a)
      expect(json_response[:meta][:pagination]).to eq(
        "results" => 205,
        "pages" => 5,
        "page" => 1,
        "per_page" => 50
      )
      expect(json_response[:links][:prev]).to be_nil
      expect(json_response[:links][:next]).to be_present
    end

    it "returns the requested page and preserves filters in its links" do
      get "/api/v1/reports/packing", params: {
        distributor_id: distributor.id,
        report_subtype: "customer",
        page: 2,
        per_page: 2
      }

      expect(response).to have_http_status(:ok)
      expect(json_response[:data].pluck(:row_number)).
        to eq([3, 4])
      expect(json_response[:meta][:pagination]).to eq(
        "results" => 205,
        "pages" => 103,
        "page" => 2,
        "per_page" => 2
      )

      {
        self: "2",
        first: "1",
        prev: "1",
        next: "3",
        last: "103"
      }.each do |link_name, page|
        uri = URI.parse(json_response[:links][link_name])
        query = Rack::Utils.parse_nested_query(uri.query)

        expect(uri.path).to eq("/api/v1/reports/packing")
        expect(query).to include(
          "distributor_id" => distributor.id.to_s,
          "report_subtype" => "customer",
          "per_page" => "2",
          "page" => page
        )
      end
    end

    it "caps the page size at 200" do
      get "/api/v1/reports/packing", params: {
        distributor_id: distributor.id,
        per_page: 999
      }

      expect(response).to have_http_status(:ok)
      expect(json_response[:data].size).to eq(200)
      expect(json_response[:meta][:pagination]).to eq(
        "results" => 205,
        "pages" => 2,
        "page" => 1,
        "per_page" => 200
      )
    end

    it "rejects page zero" do
      get "/api/v1/reports/packing", params: {
        distributor_id: distributor.id,
        page: 0
      }

      expect_api_error(:unprocessable_entity)
    end
  end

  describe "authentication" do
    it "rejects an invalid API token" do
      get "/api/v1/reports/packing",
          params: { distributor_id: distributor.id },
          headers: { "X-Api-Token" => "invalid-report-contract-token" }

      expect_api_error(:unauthorized)
      expect(Reporting::Reports::Packing::Customer).
        not_to have_received(:new)
    end

    it "rejects a user without report permission" do
      login_as create(:user)

      get "/api/v1/reports/packing",
          params: { distributor_id: distributor.id }

      expect_api_error(:unauthorized)
      expect(Reporting::Reports::Packing::Customer).
        not_to have_received(:new)
    end
  end

  describe "filter IDs" do
    before do
      login_as distributor.owner
    end

    it "returns 404 for a nonexistent order cycle" do
      get "/api/v1/reports/packing",
          params: { order_cycle_id: OrderCycle.maximum(:id).to_i + 1 }

      expect_api_error(:not_found)
      expect(Reporting::Reports::Packing::Customer).
        not_to have_received(:new)
    end

    it "checks both IDs when both are supplied" do
      get "/api/v1/reports/packing", params: {
        distributor_id: distributor.id,
        order_cycle_id: OrderCycle.maximum(:id).to_i + 1
      }

      expect_api_error(:not_found)
    end

    ["abc", "1abc", ["1", "2"]].each do |invalid_id|
      it "rejects malformed distributor ID #{invalid_id.inspect}" do
        get "/api/v1/reports/packing",
            params: { distributor_id: invalid_id }

        expect_api_error(:unprocessable_entity)
        expect(Reporting::Reports::Packing::Customer).
          not_to have_received(:new)
      end
    end
  end
end
