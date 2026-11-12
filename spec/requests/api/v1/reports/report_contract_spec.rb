# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Report API contract", swagger_doc: "v1.yaml" do
  describe "endpoint" do
    def report_get(report_type, params = {})
      get "/api/v1/reports/#{report_type}", params:
    end

    let(:json_error_detail) { json_response[:errors]&.first&.dig(:detail) }
    let(:pagination_meta) { json_response.dig(:meta, :pagination) }
    let(:pagination_links) { json_response[:links] }

    let!(:hub) { create(:distributor_enterprise, owner: hub_owner) }
    let!(:other_hub) { create(:distributor_enterprise) }
    let!(:hub_owner) { create(:user) }
    let!(:order_cycle) { create(:simple_order_cycle, coordinator: hub) }
    let!(:other_order_cycle) { create(:simple_order_cycle, coordinator: other_hub) }
    let!(:order) do
      create(
        :completed_order_with_totals,
        distributor: hub,
        order_cycle:
      )
    end
    let!(:other_order) do
      create(
        :completed_order_with_totals,
        distributor: other_hub,
        order_cycle: other_order_cycle
      )
    end

    before do
      order.update!(completed_at: 2.days.ago)
      other_order.update!(completed_at: 2.days.ago)
    end

    pagination_schema = {
      type: :object,
      required: %w[pagination],
      properties: {
        pagination: {
          type: :object,
          required: %w[results pages page per_page],
          properties: {
            results: { type: :integer, minimum: 0 },
            pages: { type: :integer, minimum: 1 },
            page: { type: :integer, minimum: 1 },
            per_page: { type: :integer, minimum: 1, maximum: 200 }
          }
        }
      }
    }

    links_schema = {
      type: :object,
      required: %w[self first prev next last],
      properties: {
        self: { type: :string },
        first: { type: :string },
        prev: { type: :string, nullable: true },
        next: { type: :string, nullable: true },
        last: { type: :string }
      }
    }

    path "/api/v1/reports/{report_type}" do
      get "Retrieve report rows" do
        tags "Reports"
        produces "application/json"
        security [{ api_key_header: [] }, { api_key_param: [] }, { session: [] }]

        description <<~TEXT
          Returns report rows using the current user's existing report permissions.

          Supply at least one of order_cycle_id or distributor_id. When both are
          supplied, both filters apply. The selected report determines the row
          fields, available subtypes and visibility rules.

          Pagination is applied after generating the complete report, preserving
          its grouping and calculations. It limits the response size, not the
          work needed to generate the report.
        TEXT

        parameter name: :report_type, in: :path, required: true,
                  schema: {
                    type: :string,
                    enum: %w[
                      packing customers order_cycle_management xero_invoices
                      products_and_inventory enterprise_fee_summary
                      orders_and_distributors orders_and_fulfillment sales_tax
                      payments suppliers bulk_coop revenues_by_hub
                    ]
                  },
                  description: "Report type from Reporting::Reports::List."
        parameter name: :report_subtype, in: :query, required: false,
                  schema: { type: :string },
                  description: "A subtype supported by the selected report. " \
                               "Defaults to that report's first subtype."
        parameter name: :order_cycle_id, in: :query, required: false,
                  schema: { type: :integer, minimum: 1 },
                  description: "Restricts results to an order cycle. " \
                               "Required unless distributor_id is supplied."
        parameter name: :distributor_id, in: :query, required: false,
                  schema: { type: :integer, minimum: 1 },
                  description: "Restricts results to a distributing enterprise. " \
                               "Required unless order_cycle_id is supplied."
        parameter name: "q[completed_at_gt]", in: :query, required: false,
                  schema: { type: :string },
                  description: "Lower completion-date filter, for example 2026-10-01. " \
                               "Uses the selected report's date handling; " \
                               "does not filter products_and_inventory."
        parameter name: "q[completed_at_lt]", in: :query, required: false,
                  schema: { type: :string },
                  description: "Upper completion-date filter, for example 2026-11-01. " \
                               "Uses the selected report's date handling; " \
                               "does not filter products_and_inventory."
        parameter name: :page, in: :query, required: false,
                  schema: { type: :integer, minimum: 1, default: 1 },
                  description: "Page of report rows."
        parameter name: :per_page, in: :query, required: false,
                  schema: { type: :integer, minimum: 1, maximum: 200, default: 50 },
                  description: "Rows per page. Values above 200 are capped at 200."
        parameter name: "X-Api-Token", in: :header, required: false,
                  schema: { type: :string }

        response "200", "packing customer report with both filters" do
          let(:report_type) { "packing" }
          let(:report_subtype) { "customer" }
          let(:order_cycle_id) { order_cycle.id }
          let(:distributor_id) { hub.id }
          let(:'q[completed_at_gt]') { 3.days.ago.iso8601 }
          let(:'q[completed_at_lt]') { Time.zone.tomorrow.iso8601 }

          before { login_as hub_owner }

          schema type: :object, properties: {
            data: {
              type: :array,
              items: { type: :object, additionalProperties: true }
            },
            meta: pagination_schema,
            links: links_schema
          }, required: %w[data meta links]

          run_test! do
            expect(response).to have_http_status :ok
            expect(json_response[:data]).to be_an(Array)
            expect(pagination_meta).to include(:results, :pages, :page, :per_page)
            expect(pagination_meta[:results]).to eq json_response[:data].count
            expect(pagination_links).to include(:self, :first, :prev, :next, :last)
          end
        end
        response "422", "neither order_cycle_id nor distributor_id" do
          let(:report_type) { "packing" }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(json_error_detail).to match(/order_cycle_id.*distributor_id/i)
          end
        end

        response "404", "nonexistent order cycle" do
          let(:report_type) { "customers" }
          let(:order_cycle_id) { OrderCycle.maximum(:id).to_i + 10_000 }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response).to have_http_status :not_found
          end
        end

        response "403", "fee-summary filter outside permitted scope" do
          let(:report_type) { "enterprise_fee_summary" }
          let(:report_subtype) { "fee_summary" }
          let(:order_cycle_id) { other_order_cycle.id }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response).to have_http_status :forbidden
            expect(json_error_detail).to include("not authorized")
          end
        end

        response "200", "valid API token without browser session (n8n path)" do
          let(:report_type) { "packing" }
          let(:report_subtype) { "customer" }
          let(:order_cycle_id) { order_cycle.id }

          let(:'X-Api-Token') { "reports-test-api-key" }

          before do
            hub_owner.update!(spree_api_key: "reports-test-api-key")
          end

          run_test! do |response|
            expect(response.status).to eq 200
            expect(json_response[:data]).to be_present
          end
        end

        response "401", "unauthenticated request" do
          let(:report_type) { "packing" }
          let(:order_cycle_id) { order_cycle.id }

          before { login_as nil }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response).to have_http_status :unauthorized
            expect(json_response[:errors].first[:detail]).
              to eq("You are not authorized to perform that action.")
            expect(json_response).not_to have_key(:data)
          end
        end

        response "401", "user managing no enterprises is unauthorized" do
          let(:report_type) { "customers" }
          let(:order_cycle_id) { order_cycle.id }

          before do
            login_as create(:user)
          end

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response).to have_http_status :unauthorized
            expect(json_response).not_to have_key(:data)
          end
        end

        response "422", "a Reporting::Errors::Base subclass uses the V1 error shape" do
          let(:report_type) { "packing" }
          let(:order_cycle_id) { order_cycle.id }

          before do
            login_as hub_owner
            allow(Reporting::Reports::Packing::Customer).to receive(:new)
              .and_raise(Reporting::Errors::MissingQueryParams)
          end

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response).to have_http_status :unprocessable_entity
            expect(json_error_detail).to be_present
          end
        end
      end
    end
  end

  describe "validation" do
    let!(:distributor) { create(:distributor_enterprise) }

    before do
      login_as distributor.owner
    end

    it "rejects an unknown report type" do
      get "/api/v1/reports/unknown", params: { distributor_id: distributor.id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:errors].first[:detail]).to eq("Report not found")
    end

    it "rejects an unknown report subtype" do
      get "/api/v1/reports/packing",
          params: { distributor_id: distributor.id, report_subtype: "unknown" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:errors].first[:detail]).to eq("Unknown report subtype")
    end

    it "rejects requests without either required filter" do
      get "/api/v1/reports/packing"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:errors].first[:detail]).
        to eq("Please supply order_cycle_id or distributor_id")
    end

    it "rejects blank required filters" do
      get "/api/v1/reports/packing",
          params: { order_cycle_id: "", distributor_id: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:errors].first[:detail]).
        to eq("Please supply order_cycle_id or distributor_id")
    end

    it "rejects unknown top-level parameters" do
      get "/api/v1/reports/packing",
          params: { distributor_id: distributor.id, unexpected: "value" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:errors].first[:detail]).to include("unexpected")
    end

    it "rejects unknown query filters for products" do
      get "/api/v1/reports/products_and_inventory",
          params: {
            distributor_id: distributor.id,
            q: { supplier_id_in: [] }
          }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:errors].first[:detail]).to include("supplier_id_in")
    end
  end

  describe "request behavior" do
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

      it "rejects a report type the user cannot access" do
        login_as distributor.owner

        get "/api/v1/reports/revenues_by_hub",
            params: { distributor_id: distributor.id }

        expect_api_error(:unauthorized)
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

      it "returns 404 for a nonexistent distributor" do
        get "/api/v1/reports/packing",
            params: { distributor_id: Enterprise.maximum(:id).to_i + 1 }

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

  describe "empty results" do
    let!(:empty_distributor) { create(:distributor_enterprise) }

    before { login_as empty_distributor.owner }

    it "returns zero pagination metadata and nil adjacent links" do
      get "/api/v1/reports/packing",
          params: { distributor_id: empty_distributor.id }

      expect(response).to have_http_status(:ok)
      expect(json_response[:data]).to eq([])
      expect(json_response[:meta][:pagination]).to eq(
        "results" => 0,
        "pages" => 1,
        "page" => 1,
        "per_page" => 50
      )
      expect(json_response[:links][:prev]).to be_nil
      expect(json_response[:links][:next]).to be_nil
    end
  end

  describe "supported report types" do
    let(:available_report_types) do
      Reporting::Reports::List.all.keys.map(&:to_s)
    end

    it "only exposes report types that exist in Reporting::Reports::List" do
      expect(Api::V1::ReportsController::SUPPORTED_REPORT_TYPES).
        to all(be_in(available_report_types))
    end

    it "documents the report types intentionally excluded from v1" do
      expect(available_report_types -
             Api::V1::ReportsController::SUPPORTED_REPORT_TYPES).
        to contain_exactly("users_and_enterprises")
    end
  end
end
