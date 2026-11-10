# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Reports", swagger_doc: "v1.yaml" do
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
  end

  describe "packing reports" do
    let!(:distributor) { create(:distributor_enterprise) }
    let!(:other_distributor) { create(:distributor_enterprise) }
    let!(:order_cycle) { create(:simple_order_cycle) }
    let!(:other_order_cycle) { create(:simple_order_cycle) }

    let!(:order) do
      create(:completed_order_with_totals, distributor:, order_cycle:)
    end

    let!(:other_hub_order) do
      create(:completed_order_with_totals,
             distributor: other_distributor, order_cycle:)
    end

    let!(:other_cycle_order) do
      create(:completed_order_with_totals,
             distributor:, order_cycle: other_order_cycle)
    end

    before do
      EnterpriseRole.create!(
        user: distributor.owner,
        enterprise: other_distributor
      )

      order.finalize!
      other_hub_order.finalize!
      other_cycle_order.finalize!

      login_as distributor.owner
    end

    def returned_products
      json_response[:data].pluck(:product)
    end

    def products_for(*orders)
      orders.flat_map do |order|
        order.line_items.map { |item| item.product.name }
      end
    end

    it "returns packing rows when both required filters are supplied" do
      get "/api/v1/reports/packing", params: {
        report_subtype: "customer",
        order_cycle_id: order_cycle.id,
        distributor_id: distributor.id
      }

      expect(response).to have_http_status(:ok)
      expect(returned_products).to match_array(products_for(order))
      expect(json_response[:data].first).to include(
        hub: distributor.name,
        quantity: order.line_items.first.quantity
      )
    end

    it "filters by order cycle when no distributor is supplied" do
      get "/api/v1/reports/packing", params: {
        order_cycle_id: order_cycle.id
      }

      expect(response).to have_http_status(:ok)
      expect(returned_products).
        to match_array(products_for(order, other_hub_order))
    end

    it "filters by distributor when no order cycle is supplied" do
      get "/api/v1/reports/packing", params: {
        distributor_id: distributor.id
      }

      expect(response).to have_http_status(:ok)
      expect(returned_products).
        to match_array(products_for(order, other_cycle_order))
    end

    it "uses the customer subtype by default" do
      get "/api/v1/reports/packing", params: {
        distributor_id: distributor.id,
        order_cycle_id: order_cycle.id
      }
      expect(response).to have_http_status(:ok)
      default_rows = json_response[:data]

      get "/api/v1/reports/packing", params: {
        distributor_id: distributor.id,
        order_cycle_id: order_cycle.id,
        report_subtype: "customer"
      }

      expect(response).to have_http_status(:ok)
      expect(json_response[:data]).to eq(default_rows)
    end

    it "translates the public date filters for packing" do
      order.update_columns(completed_at: Time.zone.parse("2026-10-15 12:00:00"))
      other_cycle_order.update_columns(
        completed_at: Time.zone.parse("2026-10-20 12:00:00")
      )

      get "/api/v1/reports/packing", params: {
        distributor_id: distributor.id,
        q: {
          completed_at_gt: "2026-10-14",
          completed_at_lt: "2026-10-16"
        }
      }

      expect(response).to have_http_status(:ok)
      expect(returned_products).to match_array(products_for(order))
    end
  end
end
