# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Payment reports", swagger_doc: "v1.yaml" do
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

  def product_totals_by_distributor
    json_response[:data].
      group_by { |row| row[:distributor] }.
      transform_values do |rows|
        rows.sum { |row| BigDecimal(row[:product_total_price].to_s) }
      end
  end

  %w[itemised_payment_totals payment_totals].each do |subtype|
    context subtype do
      context "when both hubs are managed by the user" do
        before do
          EnterpriseRole.create!(
            user: distributor.owner,
            enterprise: other_distributor
          )
        end

        it "filters totals by both order cycle and distributor" do
          get "/api/v1/reports/payments", params: {
            report_subtype: subtype,
            order_cycle_id: order_cycle.id,
            distributor_id: distributor.id
          }

          expect(response).to have_http_status(:ok)
          expect(product_totals_by_distributor).to eq(
            distributor.name => order.item_total
          )
        end

        it "filters totals by order cycle alone" do
          get "/api/v1/reports/payments", params: {
            report_subtype: subtype,
            order_cycle_id: order_cycle.id
          }

          expect(response).to have_http_status(:ok)
          expect(product_totals_by_distributor).to eq(
            distributor.name => order.item_total,
            other_distributor.name => other_hub_order.item_total
          )
        end

        it "filters totals by distributor alone" do
          get "/api/v1/reports/payments", params: {
            report_subtype: subtype,
            distributor_id: distributor.id
          }

          expect(response).to have_http_status(:ok)
          expect(product_totals_by_distributor).to eq(
            distributor.name => order.item_total + other_cycle_order.item_total
          )
        end
      end

      it "excludes orders from an unmanaged hub" do
        get "/api/v1/reports/payments", params: {
          report_subtype: subtype,
          order_cycle_id: order_cycle.id
        }

        expect(response).to have_http_status(:ok)
        expect(product_totals_by_distributor).to eq(
          distributor.name => order.item_total
        )
      end

      it "excludes orders outside the requested date range" do
        order.update!(completed_at: Time.zone.parse("2026-10-15 12:00:00"))

        get "/api/v1/reports/payments", params: {
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
