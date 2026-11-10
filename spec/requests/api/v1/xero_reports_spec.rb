# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Xero reports", swagger_doc: "v1.yaml" do
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:other_distributor) { create(:distributor_enterprise) }
  let!(:coordinator) { create(:distributor_enterprise) }
  let!(:order_cycle) { create(:simple_order_cycle, coordinator:) }
  let!(:other_order_cycle) { create(:simple_order_cycle, coordinator:) }

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
    order.finalize!
    other_hub_order.finalize!
    other_cycle_order.finalize!

    login_as distributor.owner
  end

  def returned_order_numbers
    json_response[:data].map { |row| row[:Reference] }.uniq
  end

  context "when both hubs are managed by the user" do
    before do
      EnterpriseRole.create!(
        user: distributor.owner,
        enterprise: other_distributor
      )
    end

    it "filters by both order cycle and distributor" do
      get "/api/v1/reports/xero_invoices", params: {
        order_cycle_id: order_cycle.id,
        distributor_id: distributor.id
      }

      expect(response).to have_http_status(:ok)
      expect(returned_order_numbers).to eq([order.number])
    end

    it "filters by order cycle alone" do
      get "/api/v1/reports/xero_invoices", params: {
        order_cycle_id: order_cycle.id
      }

      expect(response).to have_http_status(:ok)
      expect(returned_order_numbers).
        to match_array([order.number, other_hub_order.number])
    end

    it "filters by distributor alone" do
      get "/api/v1/reports/xero_invoices", params: {
        distributor_id: distributor.id
      }

      expect(response).to have_http_status(:ok)
      expect(returned_order_numbers).
        to match_array([order.number, other_cycle_order.number])
    end

    it "uses detailed report behavior when requested" do
      get "/api/v1/reports/xero_invoices", params: {
        report_subtype: "detailed",
        order_cycle_id: order_cycle.id,
        distributor_id: distributor.id
      }

      expect(response).to have_http_status(:ok)
      expect(returned_order_numbers).to eq([order.number])

      descriptions = json_response[:data].map { |row| row[:"*Description"] }
      expect(descriptions).to include(order.line_items.first.product_and_full_name)
    end
  end

  it "excludes another hub's orders within the requested order cycle" do
    get "/api/v1/reports/xero_invoices", params: {
      order_cycle_id: order_cycle.id
    }

    expect(response).to have_http_status(:ok)
    expect(returned_order_numbers).to eq([order.number])
  end

  it "returns no rows when explicitly requesting an unmanaged hub" do
    get "/api/v1/reports/xero_invoices", params: {
      distributor_id: other_distributor.id
    }

    expect(response).to have_http_status(:ok)
    expect(json_response[:data]).to eq([])
  end
end