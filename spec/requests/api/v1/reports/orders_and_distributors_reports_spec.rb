# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Orders and distributors reports", swagger_doc: "v1.yaml" do
  include_context "API report orders"

  context "orders_and_distributors" do
    include_examples "API report order filters", "orders_and_distributors", nil, :order_id, :id

    it "excludes orders from an unmanaged hub" do
      other_hub_order

      get "/api/v1/reports/orders_and_distributors",
          params: { order_cycle_id: order_cycle.id }

      expect(response).to have_http_status(:ok)
      expect(returned_values(:order_id)).to eq([order.id.to_s])
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
      expect(returned_values(:order_id)).to eq([order.id.to_s])
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
end
