# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Report documentation", swagger_doc: "v1.yaml" do
  let!(:distributor) { create(:distributor_enterprise) }
  let(:report_type) { "packing" }
  let(:distributor_id) { distributor.id.to_s }
  let(:'X-Api-Token') { "report-documentation-token" }

  before do
    distributor.owner.update!(spree_api_key: "report-documentation-token")
  end

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
                }

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

      response "200", "Report rows, including an empty result" do
        schema type: :object,
               required: %w[data meta links],
               properties: {
                 data: {
                   type: :array,
                   description: "Row fields vary by report and subtype.",
                   items: { type: :object, additionalProperties: true }
                 },
                 meta: {
                   type: :object,
                   required: ["pagination"],
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
                 },
                 links: {
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
               }

        run_test! do
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

      response "401", "Missing or invalid authentication, or no report permission" do
        let(:'X-Api-Token') { "" }

        schema '$ref': "#/components/schemas/error_response"

        run_test! do
          expect(json_response[:errors].first[:detail]).
            to eq("You are not authorized to perform that action.")
          expect(json_response).not_to have_key(:data)
        end
      end

      response "403", "The enterprise fee report rejects access to a requested filter" do
        let(:report_type) { "enterprise_fee_summary" }
        let(:report_subtype) { "fee_summary" }
        let(:order_cycle_id) do
          create(
            :simple_order_cycle,
            coordinator: create(:distributor_enterprise)
          ).id.to_s
        end

        schema '$ref': "#/components/schemas/error_response"

        run_test!
      end

      response "404", "An order cycle or distributor does not exist" do
        let(:distributor_id) { (Enterprise.maximum(:id).to_i + 1).to_s }

        before do
          allow(Reporting::Reports::Packing::Customer).
            to receive(:new).and_call_original
        end

        schema '$ref': "#/components/schemas/error_response"

        run_test! do
          expect(json_response).not_to have_key(:data)
          expect(Reporting::Reports::Packing::Customer).
            not_to have_received(:new)
        end
      end

      response "422", "Invalid report, subtype, filters or pagination" do
        let(:distributor_id) { "" }
        let(:order_cycle_id) { "" }

        schema '$ref': "#/components/schemas/error_response"

        run_test! do
          expect(json_response[:errors].first[:detail]).
            to eq("Please supply order_cycle_id or distributor_id")
        end
      end
    end
  end
end
