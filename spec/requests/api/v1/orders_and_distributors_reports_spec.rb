# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Orders and distributors reports", swagger_doc: "v1.yaml" do
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:other_distributor) { create(:distributor_enterprise) }
  let!(:coordinator) { create(:distributor_enterprise) }

  let!(:order_cycle) do
    create(:simple_order_cycle, coordinator:)
  end

  let!(:other_order_cycle) do
    create(:simple_order_cycle, coordinator:)
  end

  let!(:order) do
    create(:completed_order_with_totals, distributor:, order_cycle:)
  end

  let!(:other_hub_order) do
    create(
      :completed_order_with_totals,
      distributor: other_distributor,
      order_cycle:
    )
  end

  let!(:other_cycle_order) do
    create(
      :completed_order_with_totals,
      distributor:,
      order_cycle: other_order_cycle
    )
  end

  before do
    order.finalize!
    other_hub_order.finalize!
    other_cycle_order.finalize!

    login_as distributor.owner
  end

  def returned_order_ids
    json_response[:data].map { |row| row[:order_id].to_s }.uniq
  end

  context "when both hubs are managed by the user" do
    before do
      EnterpriseRole.create!(
        user: distributor.owner,
        enterprise: other_distributor
      )
    end

    it "filters by both order cycle and distributor" do
      get "/api/v1/reports/orders_and_distributors", params: {
        order_cycle_id: order_cycle.id,
        distributor_id: distributor.id
      }

      expect(response).to have_http_status(:ok)
      expect(returned_order_ids).to eq([order.id.to_s])
    end

    it "filters by order cycle alone" do
      get "/api/v1/reports/orders_and_distributors",
          params: { order_cycle_id: order_cycle.id }

      expect(response).to have_http_status(:ok)
      expect(returned_order_ids).
        to match_array([order.id.to_s, other_hub_order.id.to_s])
    end

    it "filters by distributor alone" do
      get "/api/v1/reports/orders_and_distributors",
          params: { distributor_id: distributor.id }

      expect(response).to have_http_status(:ok)
      expect(returned_order_ids).
        to match_array([order.id.to_s, other_cycle_order.id.to_s])
    end
  end

  it "excludes orders from an unmanaged hub" do
    get "/api/v1/reports/orders_and_distributors",
        params: { order_cycle_id: order_cycle.id }

    expect(response).to have_http_status(:ok)
    expect(returned_order_ids).to eq([order.id.to_s])
  end

  it "preserves customer detail masking for a supplier" do
    supplier = order.line_items.first.supplier

    create(
      :enterprise_relationship,
      parent: supplier,
      child: distributor,
      permissions_list: [:add_to_order_cycle]
    )

    distributor.update!(
      enable_producers_to_edit_orders: false,
      show_customer_names_to_suppliers: false,
      show_customer_contacts_to_suppliers: false
    )

    login_as supplier.owner

    get "/api/v1/reports/orders_and_distributors", params: {
      order_cycle_id: order_cycle.id,
      distributor_id: distributor.id
    }

    expect(response).to have_http_status(:ok)
    expect(returned_order_ids).to eq([order.id.to_s])
    expect(json_response[:data]).to all(
      include(
        customer_name: "< Hidden >",
        customer_email: "< Hidden >",
        customer_phone: "",
        customer_city: ""
      )
    )
  end
end