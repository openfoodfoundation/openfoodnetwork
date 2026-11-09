# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Reports endpoint", swagger_doc: "v1.yaml" do
  # The implementation plan is still being agreed. These tests define the API
  # contract that the V1 reports controller must satisfy once implemented.
  around { |example| skip("Api::V1::ReportsController is not implemented yet") && example.run }

  def report_get(report_type, params = {})
    get "/api/v1/reports/#{report_type}", params:
  end

  let(:json_error_detail) { json_response[:errors]&.first&.dig(:detail) }
  let(:pagination_meta) { json_response.dig(:meta, :pagination) }
  let(:pagination_links) { json_response[:links] }

  let!(:hub) { create(:distributor_enterprise, owner: hub_owner) }
  let!(:other_hub) { create(:distributor_enterprise) }
  let!(:hub_owner) { create(:user) }
  let!(:producer) { create(:supplier_enterprise) }
  let!(:order_cycle) { create(:simple_order_cycle, coordinator: hub) }
  let!(:other_order_cycle) { create(:simple_order_cycle, coordinator: other_hub) }
  let!(:order) do
    create(
      :completed_order_with_totals,
      distributor: hub,
      order_cycle:,
      line_items: [{
        variant: create(:variant, supplier: producer),
        quantity: 2
      }]
    )
  end
  let!(:other_order) do
    create(
      :completed_order_with_totals,
      distributor: other_hub,
      order_cycle: other_order_cycle,
      line_items: [{ variant: create(:variant), quantity: 1 }]
    )
  end

  before do
    hub_owner.enterprise_roles.build(enterprise: hub).save
    order.update!(completed_at: 2.days.ago)
    other_order.update!(completed_at: 2.days.ago)
  end

  path "/api/v1/reports/{report_type}" do
    get "Run a report" do
      tags "Reports"
      produces "application/json"

      parameter name: :report_type, in: :path, required: true, schema: { type: :string },
                description: "Report type from Reporting::Reports::List."
      parameter name: :report_subtype, in: :query, required: false, schema: { type: :string },
                description: "Optional subtype; defaults to the first subtype for the report."
      parameter name: :order_cycle_id, in: :query, required: false, schema: { type: :integer },
                description: "Order cycle filter. At least one of this or distributor_id is required."
      parameter name: :distributor_id, in: :query, required: false, schema: { type: :integer },
                description: "Distributor filter. At least one of this or order_cycle_id is required."
      parameter name: "q[completed_at_gt]", in: :query, required: false,
                schema: { type: :string, format: :date_time },
                description: "Completed-from filter, translated per report where necessary."
      parameter name: "q[completed_at_lt]", in: :query, required: false,
                schema: { type: :string, format: :date_time },
                description: "Completed-to filter, translated per report where necessary."
      parameter name: :page, in: :query, required: false, schema: { type: :integer, default: 1 }
      parameter name: :per_page, in: :query, required: false,
                schema: { type: :integer, default: 50, maximum: 200 }

      response "200", "packing customer report with both filters" do
        let(:report_type) { "packing" }
        let(:report_subtype) { "customer" }
        let(:order_cycle_id) { order_cycle.id }
        let(:distributor_id) { hub.id }
        let(:"q[completed_at_gt]") { 3.days.ago.iso8601 }
        let(:"q[completed_at_lt]") { Time.zone.tomorrow.iso8601 }

        before { login_as hub_owner }

        schema type: :object, properties: {
          data: { type: :array, items: { type: :object } },
          meta: pagination_schema,
          links: links_schema
        }, required: %w[data meta links]

        run_test! do
          expect(response.status).to eq 200
          expect(json_response[:data]).to be_an(Array)
          expect(pagination_meta).to include(:results, :pages, :page, :per_page)
          expect(pagination_links).to include(:self, :first, :prev, :next, :last)
        end
      end

      describe "single-filter requests" do
        response "200", "only order_cycle_id is sufficient" do
          let(:report_type) { "customers" }
          let(:order_cycle_id) { order_cycle.id }

          before { login_as hub_owner }

          run_test! do
            expect(response.status).to eq 200
          end
        end

        response "200", "only distributor_id is sufficient" do
          let(:report_type) { "customers" }
          let(:distributor_id) { hub.id }

          before { login_as hub_owner }

          run_test! do
            expect(response.status).to eq 200
          end
        end
      end

      response "200", "customers report using top-level filters" do
        let(:report_type) { "customers" }
        let(:order_cycle_id) { order_cycle.id }
        let(:distributor_id) { hub.id }

        before { login_as hub_owner }

        schema type: :object, properties: {
          data: { type: :array, items: { type: :object } },
          meta: pagination_schema,
          links: links_schema
        }

        run_test! do
          expect(response.status).to eq 200
        end
      end

      response "200", "valid API token without browser session (n8n path)" do
        let(:report_type) { "packing" }
        let(:report_subtype) { "customer" }
        let(:order_cycle_id) { order_cycle.id }

        before do
          hub_owner.update!(spree_api_key: "reports-test-api-key")
          header "X-Api-Token", "reports-test-api-key"
        end

        run_test! do |response|
          expect(response.status).to eq 200
          expect(json_response[:data]).to be_present
        end
      end

      context "when checking enterprise isolation" do
        response "200", "another hub's distributor cannot expose its rows" do
          let(:report_type) { "packing" }
          let(:report_subtype) { "customer" }
          let(:distributor_id) { other_hub.id }

          before { login_as hub_owner }

          run_test! do
            expect(response.status).to eq 200
            expect(json_response[:data]).to eq []
          end
        end

        response "200", "another hub's order cycle cannot expose its rows" do
          let(:report_type) { "customers" }
          let(:order_cycle_id) { other_order_cycle.id }

          before { login_as hub_owner }

          run_test! do
            expect(response.status).to eq 200
            expect(json_response[:data]).to eq []
          end
        end

        response "200", "xero order-cycle isolation uses documented _eq translation" do
          let(:report_type) { "xero_invoices" }
          let(:report_subtype) { "summary" }
          let(:order_cycle_id) { other_order_cycle.id }

          before { login_as hub_owner }

          run_test! do
            expect(response.status).to eq 200
            expect(json_response[:data]).to eq []
          end
        end
      end

      describe "required filters" do
        response "422", "neither order_cycle_id nor distributor_id" do
          let(:report_type) { "packing" }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(json_error_detail).to match(/order_cycle_id.*distributor_id/i)
          end
        end

        response "422", "blank filter values" do
          let(:report_type) { "packing" }
          let(:order_cycle_id) { "" }
          let(:distributor_id) { "" }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response.status).to eq 422
          end
        end
      end

      describe "unknown report definitions" do
        response "422", "unknown report type" do
          let(:report_type) { "definitely_not_a_report" }
          let(:order_cycle_id) { order_cycle.id }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(json_error_detail).to eq "Report not found"
          end
        end

        response "422", "unknown report subtype" do
          let(:report_type) { "packing" }
          let(:report_subtype) { "definitely_not_a_subtype" }
          let(:order_cycle_id) { order_cycle.id }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response.status).to eq 422
          end
        end
      end

      describe "authentication and permissions" do
        response "401", "unauthenticated request" do
          let(:report_type) { "packing" }
          let(:order_cycle_id) { order_cycle.id }

          before { login_as nil }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response.status).to eq 401
          end
        end

        response "401", "invalid API token" do
          let(:report_type) { "packing" }
          let(:order_cycle_id) { order_cycle.id }

          before do
            hub_owner.update!(spree_api_key: nil)
            header "X-Api-Token", "an-invalid-api-key"
          end

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response.status).to eq 401
          end
        end

        response "401", "enterprise user without permission for this report" do
          let(:report_type) { "users_and_enterprises" }
          let(:order_cycle_id) { order_cycle.id }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response.status).to eq 401
          end
        end

        response "200", "user managing no enterprises receives an empty report" do
          let(:report_type) { "customers" }
          let(:order_cycle_id) { order_cycle.id }

          before do
            login_as create(:user)
          end

          run_test! do
            expect(response.status).to eq 200
            expect(json_response[:data]).to eq []
          end
        end
      end

      describe "pagination" do
        response "200", "default page metadata" do
          let(:report_type) { "customers" }
          let(:distributor_id) { hub.id }

          before { login_as hub_owner }

          run_test! do
            expect(pagination_meta).to include(page: 1, per_page: 50)
          end
        end

        response "200", "results count matches report rows" do
          let(:report_type) { "packing" }
          let(:report_subtype) { "customer" }
          let(:order_cycle_id) { order_cycle.id }

          before { login_as hub_owner }

          run_test! do
            expect(pagination_meta[:results]).to eq json_response[:data].count
          end
        end

        response "200", "second page does not repeat first-page rows" do
          let(:report_type) { "packing" }
          let(:report_subtype) { "customer" }
          let(:order_cycle_id) { order_cycle.id }

          before { login_as hub_owner }

          run_test! do
            get "/api/v1/reports/packing", params: {
              report_subtype: "customer", order_cycle_id:, page: 2
            }
            expect(json_response[:links][:self]).to include("page=2")
          end
        end

        response "422", "page below one" do
          let(:report_type) { "customers" }
          let(:distributor_id) { hub.id }
          let(:page) { 0 }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response.status).to eq 422
          end
        end

        response "200", "per_page is capped at the documented maximum" do
          let(:report_type) { "packing" }
          let(:report_subtype) { "customer" }
          let(:order_cycle_id) { order_cycle.id }
          let(:per_page) { JsonApiPagination::MAX_PER_PAGE + 1 }

          before { login_as hub_owner }

          run_test! do
            expect(pagination_meta[:per_page]).to eq JsonApiPagination::MAX_PER_PAGE
          end
        end
      end

      describe "proposed nonexistent-ID semantics" do
        # Pending Maikel/Emily sign-off. If empty-data behavior is chosen instead,
        # change these examples to 200 and assert no rows rather than deleting them.
        response "404", "nonexistent order cycle" do
          let(:report_type) { "customers" }
          let(:order_cycle_id) { OrderCycle.maximum(:id).to_i + 10_000 }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response.status).to eq 404
          end
        end

        response "404", "nonexistent distributor" do
          let(:report_type) { "customers" }
          let(:distributor_id) { Enterprise.maximum(:id).to_i + 10_000 }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response.status).to eq 404
          end
        end
      end

      describe "enterprise fee summary errors" do
        response "403", "fee-summary filter outside permitted scope" do
          let(:report_type) { "enterprise_fee_summary" }
          let(:report_subtype) { "fee_summary" }
          let(:order_cycle_id) { other_order_cycle.id }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response.status).to eq 403
            expect(json_error_detail).to include("not authorized")
          end
        end

        response "422", "fee-summary invalid date range" do
          let(:report_type) { "enterprise_fee_summary" }
          let(:report_subtype) { "fee_summary" }
          let(:distributor_id) { hub.id }
          let(:"q[completed_at_gt]") { "not-a-date" }

          before { login_as hub_owner }

          schema '$ref': "#/components/schemas/error_response"

          run_test! do
            expect(response.status).to eq 422
          end
        end
      end

      describe "generic reporting errors" do
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
            expect(response.status).to eq 422
            expect(json_error_detail).to be_present
          end
        end
      end

      describe "customer-data masking" do
        response "200", "P-OC supplier sees hidden customer details" do
          let(:report_type) { "packing" }
          let(:report_subtype) { "customer" }
          let(:order_cycle_id) { order_cycle.id }

          before do
            create(:enterprise_relationship, parent: producer, child: hub,
                                             permissions_list: [:add_to_order_cycle])
            login_as producer.owner
          end

          run_test! do
            expect(json_response[:data].flat_map(&:values)).to include("< Hidden >")
          end
        end

        response "200", "hub manager sees real customer details" do
          let(:report_type) { "packing" }
          let(:report_subtype) { "customer" }
          let(:order_cycle_id) { order_cycle.id }

          before { login_as hub_owner }

          run_test! do
            values = json_response[:data].flat_map(&:values)
            expect(values).not_to include("< Hidden >")
            expect(values).to include(order.bill_address.firstname)
          end
        end
      end
    end
  end

  def pagination_schema
    {
      type: :object,
      properties: {
        pagination: {
          type: :object,
          properties: {
            results: { type: :integer },
            pages: { type: :integer },
            page: { type: :integer },
            per_page: { type: :integer }
          },
          required: %w[results pages page per_page]
        }
      },
      required: %w[pagination]
    }
  end

  def links_schema
    {
      type: :object,
      properties: {
        self: { type: :string, nullable: true },
        first: { type: :string, nullable: true },
        prev: { type: :string, nullable: true },
        next: { type: :string, nullable: true },
        last: { type: :string, nullable: true }
      }
    }
  end
end
