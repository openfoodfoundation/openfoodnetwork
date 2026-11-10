# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Packing reports", swagger_doc: "v1.yaml" do
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

  it "does not expose another hub's rows" do
    unmanaged_hub = create(:distributor_enterprise)

    get "/api/v1/reports/packing", params: {
      report_subtype: "customer",
      distributor_id: unmanaged_hub.id
    }

    expect(response).to have_http_status(:ok)
    expect(json_response[:data]).to eq([])
  end

  context "with customer detail masking" do
    it "hides customer details from a supplier with add-to-order-cycle permission" do
      supplier = order.line_items.first.supplier

      create(
        :enterprise_relationship,
        parent: supplier,
        child: distributor,
        permissions_list: [:add_to_order_cycle]
      )

      login_as supplier.owner

      get "/api/v1/reports/packing", params: {
        report_subtype: "customer",
        order_cycle_id: order_cycle.id
      }

      expect(json_response[:data].flat_map(&:values)).to include("< Hidden >")
    end

    it "shows customer details to the hub manager" do
      get "/api/v1/reports/packing", params: {
        report_subtype: "customer",
        order_cycle_id: order_cycle.id
      }

      values = json_response[:data].flat_map(&:values)
      expect(values).not_to include("< Hidden >")
      expect(values).to include(order.bill_address.firstname)
    end
  end
end
