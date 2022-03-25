# frozen_string_literal: true

require 'spec_helper'

require 'open_food_network/products_and_inventory_report'

module OpenFoodNetwork
  describe LettuceShareReport do
    let(:user) { create(:user) }
    let(:base_report) {
      ProductsAndInventoryReport.new(user, { report_subtype: 'lettuce_share' }, true)
    }
    let(:report) { base_report.report }
    let(:variant) { create(:variant) }

    describe "grower and method" do
      it "shows just the producer when there is no certification" do
        allow(report).to receive(:producer_name) { "Producer" }
        allow(report).to receive(:certification) { "" }

        expect(report.send(:grower_and_method, variant)).to eq("Producer")
      end

      it "shows producer and certification when a certification is present" do
        allow(report).to receive(:producer_name) { "Producer" }
        allow(report).to receive(:certification) { "Method" }

        expect(report.send(:grower_and_method, variant)).to eq("Producer (Method)")
      end
    end

    describe "gst" do
      it "handles tax category without rates" do
        expect(report.send(:gst, variant)).to eq(0)
      end
    end

    describe "table" do
      it "handles no items" do
        expect(report.table_rows).to eq []
      end

      describe "lists" do
        let(:variant2) { create(:variant) }
        let(:variant3) { create(:variant) }
        let(:variant4) { create(:variant, on_hand: 0, on_demand: true) }
        let(:hub_address) {
          create(:address, address1: "distributor address", city: 'The Shire', zipcode: "1234")
        }
        let(:hub) { create(:distributor_enterprise, address: hub_address) }
        let(:variant2_override) { create(:variant_override, hub: hub, variant: variant2) }
        let(:variant3_override) {
          create(:variant_override, hub: hub, variant: variant3, count_on_hand: 0)
        }

        it "all items" do
          allow(base_report).to receive(:child_variants) {
                                  Spree::Variant.where(id: [variant, variant2, variant3])
                                }
          expect(report.table_rows.count).to eq 3
        end

        it "only available items" do
          variant.on_hand = 0
          allow(base_report).to receive(:child_variants) {
                                  Spree::Variant.where(id: [variant, variant2, variant3, variant4])
                                }
          expect(report.table_rows.count).to eq 3
        end

        it "only available items considering overrides" do
          create(:exchange, incoming: false, receiver_id: hub.id,
                            variants: [variant, variant2, variant3])
          # create the overrides
          variant2_override
          variant3_override
          allow(base_report).to receive(:child_variants) {
                                  Spree::Variant.where(id: [variant, variant2, variant3])
                                }
          allow(base_report).to receive(:params) {
            { distributor_id: hub.id, report_subtype: 'lettuce_share' }
          }
          rows = report.table_rows
          expect(rows.count).to eq 2
          expect(rows.map{ |row| row[0] }).to include variant.product.name, variant2.product.name
        end
      end
    end
  end
end
