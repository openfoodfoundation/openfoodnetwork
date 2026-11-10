# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Bulk co-op and revenue reports", swagger_doc: "v1.yaml" do
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
    [
      [order, "Selected product"],
      [other_hub_order, "Other hub product"],
      [other_cycle_order, "Other cycle product"]
    ].each do |record, product_name|
      line_item = record.line_items.first

      line_item.product.update!(
        name: product_name,
        group_buy: true
      )
      line_item.update!(product_name:)

      record.finalize!
    end
  end

  def returned_products
    json_response[:data].filter_map { |row| row[:product].presence }.uniq
  end

  def order_counts_by_hub
    json_response[:data].to_h do |row|
      [row[:hub], row[:total_orders].to_i]
    end
  end

  describe "bulk co-op" do
    before do
      login_as distributor.owner
    end

    %w[supplier_report allocation packing_sheets].each do |subtype|
      context subtype do
        before do
          EnterpriseRole.create!(
            user: distributor.owner,
            enterprise: other_distributor
          )
        end

        it "filters by both order cycle and distributor" do
          get "/api/v1/reports/bulk_coop", params: {
            report_subtype: subtype,
            order_cycle_id: order_cycle.id,
            distributor_id: distributor.id
          }

          expect(response).to have_http_status(:ok)
          expect(returned_products).to eq(["Selected product"])
        end

        it "filters by order cycle alone" do
          get "/api/v1/reports/bulk_coop", params: {
            report_subtype: subtype,
            order_cycle_id: order_cycle.id
          }

          expect(response).to have_http_status(:ok)
          expect(returned_products).
            to match_array(["Selected product", "Other hub product"])
        end

        it "filters by distributor alone" do
          get "/api/v1/reports/bulk_coop", params: {
            report_subtype: subtype,
            distributor_id: distributor.id
          }

          expect(response).to have_http_status(:ok)
          expect(returned_products).
            to match_array(["Selected product", "Other cycle product"])
        end
      end
    end

    it "defaults to the supplier report and excludes unmanaged hubs" do
      get "/api/v1/reports/bulk_coop",
          params: { order_cycle_id: order_cycle.id }

      expect(response).to have_http_status(:ok)
      expect(returned_products).to eq(["Selected product"])
    end

    it "renders the customer payments subtype" do
      get "/api/v1/reports/bulk_coop", params: {
        report_subtype: "customer_payments",
        order_cycle_id: order_cycle.id,
        distributor_id: distributor.id
      }

      expect(response).to have_http_status(:ok)
      expect(json_response[:data].size).to eq(1)
      expect(BigDecimal(json_response[:data].first[:total_cost].to_s)).
        to eq(order.total)
    end

    it "applies date filters" do
      order.update!(completed_at: Time.zone.parse("2026-10-15 12:00:00"))

      get "/api/v1/reports/bulk_coop", params: {
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

  describe "revenues by hub" do
    context "as a superadmin" do
      before do
        login_as create(:admin_user)
      end

      it "filters by both order cycle and distributor" do
        get "/api/v1/reports/revenues_by_hub", params: {
          order_cycle_id: order_cycle.id,
          distributor_id: distributor.id
        }

        expect(response).to have_http_status(:ok)
        expect(order_counts_by_hub).to eq(distributor.name => 1)

        row = json_response[:data].first
        expect(BigDecimal(row[:total_incl_tax].to_s)).to eq(order.total)
      end

      it "filters by order cycle alone" do
        get "/api/v1/reports/revenues_by_hub",
            params: { order_cycle_id: order_cycle.id }

        expect(response).to have_http_status(:ok)
        expect(order_counts_by_hub).to eq(
          distributor.name => 1,
          other_distributor.name => 1
        )
      end

      it "filters by distributor alone" do
        get "/api/v1/reports/revenues_by_hub",
            params: { distributor_id: distributor.id }

        expect(response).to have_http_status(:ok)
        expect(order_counts_by_hub).to eq(distributor.name => 2)
      end

      it "applies date filters" do
        order.update!(completed_at: Time.zone.parse("2026-10-15 12:00:00"))

        get "/api/v1/reports/revenues_by_hub", params: {
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

    it "rejects an ordinary hub manager" do
      login_as distributor.owner

      get "/api/v1/reports/revenues_by_hub",
          params: { distributor_id: distributor.id }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response[:errors]).to include(
        include(detail: "You are not authorized to perform that action.")
      )
    end
  end
end
