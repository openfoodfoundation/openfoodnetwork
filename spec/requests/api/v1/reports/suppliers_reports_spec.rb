# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Suppliers reports", swagger_doc: "v1.yaml" do
  include_context "API report orders"

  {
    "suppliers" => "pay_your_suppliers"
  }.each do |report_type, subtype|
    context report_type do
      include_examples "API report order filters", report_type, subtype, :order_number, :number

      it "excludes orders from an unrelated hub and order cycle" do
        unrelated_hub = create(:distributor_enterprise)
        unrelated_cycle = create(
          :simple_order_cycle,
          coordinator: unrelated_hub
        )
        completed_order(unrelated_hub, unrelated_cycle)

        get "/api/v1/reports/#{report_type}", params: {
          report_subtype: subtype,
          distributor_id: unrelated_hub.id
        }

        expect(response).to have_http_status(:ok)
        expect(json_response[:data]).to eq([])
      end

      it "excludes orders outside the requested date range" do
        order.update!(completed_at: Time.zone.parse("2026-10-15 12:00:00"))

        get "/api/v1/reports/#{report_type}", params: {
          report_subtype: subtype,
          order_cycle_id: order_cycle.id,
          distributor_id: distributor.id,
          q: {
            completed_at_gt: "2026-10-16",
            completed_at_lt: "2026-10-17"
          }
        }

        expect(response).to have_http_status(:ok)
        expect(json_response[:data]).to eq([])
      end
    end
  end
end
