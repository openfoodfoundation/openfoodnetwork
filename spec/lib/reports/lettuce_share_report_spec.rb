# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module ProductsAndInventory
      describe LettuceShare do
        let(:user) { create(:user) }
        let(:report) { LettuceShare.new(user) }
        let(:variant) { create(:variant) }

        describe "grower and method" do
          it "shows just the producer when there is no certification" do
            allow(report).to receive(:producer_name) { "Producer" }
            allow(report).to receive(:certification) { "" }

            expect(report.__send__(:grower_and_method, variant)).to eq("Producer")
          end

          it "shows producer and certification when a certification is present" do
            allow(report).to receive(:producer_name) { "Producer" }
            allow(report).to receive(:certification) { "Method" }

            expect(report.__send__(:grower_and_method, variant)).to eq("Producer (Method)")
          end
        end

        describe "gst" do
          it "handles tax category without rates" do
            expect(report.__send__(:gst, variant)).to eq(0)
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
              allow(report).to receive(:child_variants) {
                                 Spree::Variant.where(id: [variant, variant2, variant3])
                               }
              expect(report.table_rows.count).to eq 3
            end

            it "only available items" do
              variant.on_hand = 0
              allow(report).to receive(:child_variants) {
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
              allow(report).to receive(:child_variants) {
                                 Spree::Variant.where(id: [variant, variant2, variant3])
                               }
              allow(report).to receive(:params) {
                { distributor_id: hub.id, report_subtype: 'lettuce_share' }
              }
              rows = report.table_rows
              expect(rows.count).to eq 2
              expect(rows.map{ |row|
                       row[0]
                     } ).to include variant.product.name, variant2.product.name
            end
          end
        end
      end
    end
  end
end
