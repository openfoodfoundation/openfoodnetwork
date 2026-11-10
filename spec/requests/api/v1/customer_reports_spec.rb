# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Customer reports", swagger_doc: "v1.yaml" do
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

  def returned_emails
    json_response[:data].map { |row| row[:email] }
  end

  it "filters by both order cycle and distributor without a subtype" do
    get "/api/v1/reports/customers", params: {
      order_cycle_id: order_cycle.id,
      distributor_id: distributor.id
    }

    expect(response).to have_http_status(:ok)
    expect(returned_emails).to eq([order.email])
    expect(json_response[:data].first).to include(
      hub: distributor.name,
      total_orders: 1
    )
  end

  it "filters by order cycle alone" do
    get "/api/v1/reports/customers", params: {
      order_cycle_id: order_cycle.id
    }

    expect(response).to have_http_status(:ok)
    expect(returned_emails).to match_array([order.email, other_hub_order.email])
  end

  it "filters by distributor alone" do
    get "/api/v1/reports/customers", params: {
      distributor_id: distributor.id
    }

    expect(response).to have_http_status(:ok)
    expect(returned_emails).to match_array([order.email, other_cycle_order.email])
  end
end