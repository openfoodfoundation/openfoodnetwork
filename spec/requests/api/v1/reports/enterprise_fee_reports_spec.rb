# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Enterprise fee reports", swagger_doc: "v1.yaml" do
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:producer) { create(:supplier_enterprise) }

  let!(:shipping_method) do
    create(
      :shipping_method,
      :per_item,
      amount: 1,
      name: "Report shipping fee",
      distributors: [distributor]
    )
  end

  let!(:payment_method) do
    create(:payment_method, distributors: [distributor])
  end

  let!(:order_cycle) do
    create(:simple_order_cycle, coordinator: distributor)
  end

  let!(:variant) do
    create(
      :variant,
      :with_order_cycle,
      enterprise: producer,
      producer:,
      coordinator: distributor,
      distributor:,
      order_cycle:
    )
  end

  let!(:order) do
    create(
      :order,
      :with_line_item,
      :completed,
      customer: create(:customer, enterprise: distributor),
      distributor:,
      order_cycle:,
      variant:,
      shipping_method:,
      payment_method:
    )
  end

  before do
    login_as distributor.owner
  end

  it "returns fee rows with both filters" do
    get "/api/v1/reports/enterprise_fee_summary", params: {
      report_subtype: "fee_summary",
      order_cycle_id: order_cycle.id,
      distributor_id: distributor.id
    }

    expect(response).to have_http_status(:ok)
    expect(json_response[:data]).to include(
      include(
        fee_name: shipping_method.name,
        enterprise_name: distributor.name
      )
    )
  end

  it "accepts an order cycle without a distributor" do
    get "/api/v1/reports/enterprise_fee_summary", params: {
      report_subtype: "fee_summary",
      order_cycle_id: order_cycle.id
    }

    expect(response).to have_http_status(:ok)
    expect(json_response[:data]).to include(
      include(fee_name: shipping_method.name)
    )
  end

  it "accepts a distributor without an order cycle" do
    get "/api/v1/reports/enterprise_fee_summary", params: {
      report_subtype: "fee_summary",
      distributor_id: distributor.id
    }

    expect(response).to have_http_status(:ok)
    expect(json_response[:data]).to include(
      include(fee_name: shipping_method.name)
    )
  end

  it "rejects an order cycle the user cannot access" do
    other_distributor = create(:distributor_enterprise)
    other_cycle = create(:simple_order_cycle, coordinator: other_distributor)

    get "/api/v1/reports/enterprise_fee_summary", params: {
      report_subtype: "fee_summary",
      order_cycle_id: other_cycle.id
    }

    expect(response).to have_http_status(:forbidden)
    expect(json_response[:errors]).to include(
      include(detail: kind_of(String))
    )
    expect(json_response).not_to have_key(:data)
  end

  it "rejects a reversed date range" do
    get "/api/v1/reports/enterprise_fee_summary", params: {
      report_subtype: "fee_summary",
      order_cycle_id: order_cycle.id,
      q: {
        completed_at_gt: "2026-10-20",
        completed_at_lt: "2026-10-10"
      }
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json_response[:errors]).to include(
      include(detail: kind_of(String))
    )
    expect(json_response).not_to have_key(:data)
  end

  it "rejects an invalid date filter" do
    get "/api/v1/reports/enterprise_fee_summary", params: {
      report_subtype: "fee_summary",
      order_cycle_id: order_cycle.id,
      q: { completed_at_gt: "not-a-date" }
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json_response[:errors]).to include(
      include(detail: kind_of(String))
    )
    expect(json_response).not_to have_key(:data)
  end

  it "excludes fees from another order cycle" do
    other_cycle = create(:simple_order_cycle, coordinator: distributor)
    other_shipping_method = create(
      :shipping_method,
      :per_item,
      amount: 2,
      name: "Other cycle shipping fee",
      distributors: [distributor]
    )
    other_variant = create(
      :variant,
      :with_order_cycle,
      enterprise: producer,
      producer:,
      coordinator: distributor,
      distributor:,
      order_cycle: other_cycle
    )

    create(
      :order,
      :with_line_item,
      :completed,
      customer: create(:customer, enterprise: distributor),
      distributor:,
      order_cycle: other_cycle,
      variant: other_variant,
      shipping_method: other_shipping_method,
      payment_method:
    )

    get "/api/v1/reports/enterprise_fee_summary", params: {
      report_subtype: "fee_summary",
      order_cycle_id: order_cycle.id
    }

    expect(response).to have_http_status(:ok)

    fee_names = json_response[:data].pluck(:fee_name)
    expect(fee_names).to include(shipping_method.name)
    expect(fee_names).not_to include(other_shipping_method.name)
  end

  it "excludes fees outside the requested date range" do
    order.update!(completed_at: Time.zone.parse("2026-10-15 12:00:00"))

    get "/api/v1/reports/enterprise_fee_summary", params: {
      report_subtype: "fee_summary",
      order_cycle_id: order_cycle.id,
      q: {
        completed_at_gt: "2026-10-16",
        completed_at_lt: "2026-10-17"
      }
    }

    expect(response).to have_http_status(:ok)
    expect(json_response[:data]).to eq([])
  end

  it "includes fees within the requested date range" do
    order.update!(completed_at: Time.zone.parse("2026-10-15 12:00:00"))

    get "/api/v1/reports/enterprise_fee_summary", params: {
      report_subtype: "fee_summary",
      order_cycle_id: order_cycle.id,
      q: {
        completed_at_gt: "2026-10-14",
        completed_at_lt: "2026-10-16"
      }
    }

    expect(response).to have_http_status(:ok)
    expect(json_response[:data]).to include(
      include(fee_name: shipping_method.name)
    )
  end
end
