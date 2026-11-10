# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Enterprise fee tax reports", swagger_doc: "v1.yaml" do
  let!(:distributor) do
    create(:distributor_enterprise, is_primary_producer: true)
  end

  let!(:other_distributor) do
    create(:distributor_enterprise, is_primary_producer: true)
  end

  let!(:order_cycle) do
    create(:simple_order_cycle, coordinator: distributor)
  end

  let!(:other_order_cycle) do
    create(:simple_order_cycle, coordinator: distributor)
  end

  before do
    EnterpriseRole.create!(
      user: distributor.owner,
      enterprise: other_distributor
    )

    create_fee_order(distributor, order_cycle, "Selected fee")
    create_fee_order(distributor, other_order_cycle, "Other cycle fee")
    create_fee_order(other_distributor, order_cycle, "Other hub fee")

    login_as distributor.owner
  end

  def create_fee_order(hub, cycle, fee_name)
    shipping_method = create(:shipping_method, distributors: [hub])
    variant = create(:variant, enterprise: hub)
    fee = create(
      :enterprise_fee,
      :per_item,
      enterprise: hub,
      amount: 15,
      name: fee_name,
      fee_type: "transport"
    )

    incoming = cycle.exchanges.create!(
      incoming: true,
      sender: hub,
      receiver: cycle.coordinator
    )
    outgoing = cycle.exchanges.create!(
      incoming: false,
      sender: cycle.coordinator,
      receiver: hub
    )

    incoming.exchange_fees.create!(enterprise_fee: fee)
    incoming.exchange_variants.create!(variant:)
    outgoing.exchange_variants.create!(variant:)

    create(
      :order,
      :with_line_item,
      variant:,
      distributor: hub,
      order_cycle: cycle,
      shipping_method:,
      ship_address: create(:address)
    ).tap do |order|
      order.recreate_all_fees!
      Orders::WorkflowService.new(order).complete!
    end
  end

  def returned_fee_names
    json_response[:data].
      map { |row| row[:enterprise_fee_name] }.
      compact
  end

  %w[
    enterprise_fees_with_tax_report_by_order
    enterprise_fees_with_tax_report_by_producer
  ].each do |subtype|
    context subtype do
      it "filters by both order cycle and distributor" do
        get "/api/v1/reports/enterprise_fee_summary", params: {
          report_subtype: subtype,
          order_cycle_id: order_cycle.id,
          distributor_id: distributor.id
        }

        expect(response).to have_http_status(:ok)
        expect(returned_fee_names).to include("Selected fee")
        expect(returned_fee_names).
          not_to include("Other cycle fee", "Other hub fee")
      end

      it "filters by order cycle alone" do
        get "/api/v1/reports/enterprise_fee_summary", params: {
          report_subtype: subtype,
          order_cycle_id: order_cycle.id
        }

        expect(response).to have_http_status(:ok)
        expect(returned_fee_names).
          to include("Selected fee", "Other hub fee")
        expect(returned_fee_names).not_to include("Other cycle fee")
      end

      it "filters by distributor alone" do
        get "/api/v1/reports/enterprise_fee_summary", params: {
          report_subtype: subtype,
          distributor_id: distributor.id
        }

        expect(response).to have_http_status(:ok)
        expect(returned_fee_names).
          to include("Selected fee", "Other cycle fee")
        expect(returned_fee_names).not_to include("Other hub fee")
      end

      it "excludes fees from an unrelated hub and order cycle" do
        unrelated_hub = create(
          :distributor_enterprise,
          is_primary_producer: true
        )
        unrelated_cycle = create(
          :simple_order_cycle,
          coordinator: unrelated_hub
        )
        create_fee_order(unrelated_hub, unrelated_cycle, "Unrelated fee")

        get "/api/v1/reports/enterprise_fee_summary", params: {
          report_subtype: subtype,
          distributor_id: unrelated_hub.id
        }

        expect(response).to have_http_status(:ok)
        expect(json_response[:data]).to eq([])
      end
    end
  end
end