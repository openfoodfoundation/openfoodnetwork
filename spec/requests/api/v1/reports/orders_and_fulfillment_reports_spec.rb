# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Orders and fulfillment reports", swagger_doc: "v1.yaml" do
  let(:distributor) { create(:distributor_enterprise) }
  let(:other_distributor) { create(:distributor_enterprise) }
  let(:coordinator) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle, coordinator:) }
  let(:other_order_cycle) { create(:simple_order_cycle, coordinator:) }

  let!(:order) { completed_order(distributor, order_cycle) }
  let(:other_hub_order) { completed_order(other_distributor, order_cycle) }
  let(:other_cycle_order) { completed_order(distributor, other_order_cycle) }

  before do
    login_as distributor.owner
  end

  def completed_order(hub, cycle)
    create(
      :completed_order_with_totals,
      distributor: hub,
      order_cycle: cycle
    ).tap(&:finalize!)
  end

  def returned_values(field)
    json_response[:data].
      filter_map { |row| row[field].presence&.to_s }.
      uniq
  end

  shared_examples "order filters" do |report_type, subtype, field, identifier|
    context "when both hubs are managed by the user" do
      before do
        EnterpriseRole.create!(
          user: distributor.owner,
          enterprise: other_distributor
        )
        other_hub_order
        other_cycle_order
      end

      let(:report_options) do
        subtype ? { report_subtype: subtype } : {}
      end

      it "filters by both order cycle and distributor" do
        get "/api/v1/reports/#{report_type}", params: report_options.merge(
          order_cycle_id: order_cycle.id,
          distributor_id: distributor.id
        )

        expect(response).to have_http_status(:ok)
        expect(returned_values(field)).
          to eq([order.public_send(identifier).to_s])
      end

      it "filters by order cycle alone" do
        get "/api/v1/reports/#{report_type}", params: report_options.merge(
          order_cycle_id: order_cycle.id
        )

        expect(response).to have_http_status(:ok)
        expect(returned_values(field)).to match_array(
          [
            order.public_send(identifier).to_s,
            other_hub_order.public_send(identifier).to_s
          ]
        )
      end

      it "filters by distributor alone" do
        get "/api/v1/reports/#{report_type}", params: report_options.merge(
          distributor_id: distributor.id
        )

        expect(response).to have_http_status(:ok)
        expect(returned_values(field)).to match_array(
          [
            order.public_send(identifier).to_s,
            other_cycle_order.public_send(identifier).to_s
          ]
        )
      end
    end
  end
  {
    "orders_and_fulfillment" => "order_cycle_customer_totals"
  }.each do |report_type, subtype|
    context report_type do
      include_examples "order filters", report_type, subtype, :order_number, :number

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
