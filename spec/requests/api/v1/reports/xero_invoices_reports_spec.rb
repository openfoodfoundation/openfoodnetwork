# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Xero invoices reports", swagger_doc: "v1.yaml" do
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
  context "xero_invoices" do
    include_examples "order filters", "xero_invoices", nil, :Reference, :number

    it "uses detailed report behavior when requested" do
      get "/api/v1/reports/xero_invoices", params: {
        report_subtype: "detailed",
        order_cycle_id: order_cycle.id,
        distributor_id: distributor.id
      }

      expect(response).to have_http_status(:ok)
      expect(returned_values(:Reference)).to eq([order.number])

      descriptions = json_response[:data].pluck(:'*Description')
      expect(descriptions).to include(order.line_items.first.product_and_full_name)
    end

    it "excludes another hub's orders within the requested order cycle" do
      other_hub_order

      get "/api/v1/reports/xero_invoices",
          params: { order_cycle_id: order_cycle.id }

      expect(response).to have_http_status(:ok)
      expect(returned_values(:Reference)).to eq([order.number])
    end

    it "returns no rows when explicitly requesting an unmanaged hub" do
      other_hub_order

      get "/api/v1/reports/xero_invoices",
          params: { distributor_id: other_distributor.id }

      expect(response).to have_http_status(:ok)
      expect(json_response[:data]).to eq([])
    end
  end
end
