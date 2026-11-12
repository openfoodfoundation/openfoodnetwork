# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Order cycle management reports", swagger_doc: "v1.yaml" do
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:other_distributor) { create(:distributor_enterprise) }
  let!(:order_cycle) { create(:simple_order_cycle) }
  let!(:other_order_cycle) { create(:simple_order_cycle) }

  let!(:order) do
    create(:completed_order_with_totals,
           distributor:, order_cycle:,
           special_instructions: "Selected order")
  end

  let!(:other_hub_order) do
    create(:completed_order_with_totals,
           distributor: other_distributor, order_cycle:,
           special_instructions: "Other hub")
  end

  let!(:other_cycle_order) do
    create(:completed_order_with_totals,
           distributor:, order_cycle: other_order_cycle,
           special_instructions: "Other cycle")
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

  def returned_instructions
    json_response[:data].map { |row| row[:special_instructions] }
  end

  it "filters delivery rows by both order cycle and distributor" do
    get "/api/v1/reports/order_cycle_management", params: {
      report_subtype: "delivery",
      order_cycle_id: order_cycle.id,
      distributor_id: distributor.id
    }

    expect(response).to have_http_status(:ok)
    expect(returned_instructions).to eq(["Selected order"])
  end

  it "filters delivery rows by order cycle alone" do
    get "/api/v1/reports/order_cycle_management", params: {
      report_subtype: "delivery",
      order_cycle_id: order_cycle.id
    }

    expect(response).to have_http_status(:ok)
    expect(returned_instructions).to match_array(["Selected order", "Other hub"])
  end

  it "filters delivery rows by distributor alone" do
    get "/api/v1/reports/order_cycle_management", params: {
      report_subtype: "delivery",
      distributor_id: distributor.id
    }

    expect(response).to have_http_status(:ok)
    expect(returned_instructions).to match_array(["Selected order", "Other cycle"])
  end
end
