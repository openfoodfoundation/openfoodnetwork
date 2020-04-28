# frozen_string_literal: true

require "spec_helper"

module OrderManagement
  module Subscriptions
    describe VariantsList do
      describe "variant eligibility for subscription" do
        let!(:shop) { create(:distributor_enterprise) }
        let!(:producer) { create(:supplier_enterprise) }
        let!(:product) { create(:product, supplier: producer) }
        let!(:variant) { product.variants.first }

        let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
        let!(:subscription) { create(:subscription, shop: shop, schedule: schedule) }
        let!(:subscription_line_item) do
          create(:subscription_line_item, subscription: subscription, variant: variant)
        end

        let(:current_order_cycle) do
          create(:simple_order_cycle, coordinator: shop, orders_open_at: 1.week.ago,
                                      orders_close_at: 1.week.from_now)
        end

        let(:future_order_cycle) do
          create(:simple_order_cycle, coordinator: shop, orders_open_at: 1.week.from_now,
                                      orders_close_at: 2.weeks.from_now)
        end

        let(:past_order_cycle) do
          create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.weeks.ago,
                                      orders_close_at: 1.week.ago)
        end

        let!(:order_cycle) { current_order_cycle }

        context "if the shop is the supplier for the product" do
          let!(:producer) { shop }

          it "is eligible" do
            expect(described_class.eligible_variants(shop)).to include(variant)
          end
        end

        context "if the supplier is permitted for the shop" do
          let!(:enterprise_relationship) {
            create(:enterprise_relationship, child: shop,
                                             parent: product.supplier,
                                             permissions_list: [:add_to_order_cycle])
          }

          it "is eligible" do
            expect(described_class.eligible_variants(shop)).to include(variant)
          end
        end

        context "if the variant is involved in an exchange" do
          let!(:order_cycle) { create(:simple_order_cycle, coordinator: shop) }
          let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }

          context "if it is an incoming exchange where the shop is the receiver" do
            let!(:incoming_exchange) {
              order_cycle.exchanges.create(sender: product.supplier,
                                           receiver: shop,
                                           incoming: true, variants: [variant])
            }

            it "is not eligible" do
              expect(described_class.eligible_variants(shop)).to_not include(variant)
            end
          end

          context "if it is an outgoing exchange where the shop is the receiver" do
            let!(:outgoing_exchange) {
              order_cycle.exchanges.create(sender: product.supplier,
                                           receiver: shop,
                                           incoming: false,
                                           variants: [variant])
            }

            context "if the order cycle is currently open" do
              let!(:order_cycle) { current_order_cycle }

              it "is eligible" do
                expect(described_class.eligible_variants(shop)).to include(variant)
              end
            end

            context "if the order cycle opens in the future" do
              let!(:order_cycle) { future_order_cycle }

              it "is eligible" do
                expect(described_class.eligible_variants(shop)).to include(variant)
              end
            end

            context "if the order cycle closed in the past" do
              let!(:order_cycle) { past_order_cycle }

              it "is eligible" do
                expect(described_class.eligible_variants(shop)).to include(variant)
              end
            end
          end
        end

        context "if the variant is unrelated" do
          it "is not eligible" do
            expect(described_class.eligible_variants(shop)).to_not include(variant)
          end
        end
      end

      describe "checking if variant in open and upcoming order cycles" do
        let!(:shop) { create(:enterprise) }
        let!(:product) { create(:product) }
        let!(:variant) { product.variants.first }
        let!(:schedule) { create(:schedule) }

        context "if the variant is involved in an exchange" do
          let!(:order_cycle) { create(:simple_order_cycle, coordinator: shop) }
          let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }

          context "if it is an incoming exchange where the shop is the receiver" do
            let!(:incoming_exchange) {
              order_cycle.exchanges.create(sender: product.supplier,
                                           receiver: shop,
                                           incoming: true,
                                           variants: [variant])
            }

            it "is is false" do
              expect(described_class).not_to be_in_open_and_upcoming_order_cycles(shop,
                                                                                  schedule,
                                                                                  variant)
            end
          end

          context "if it is an outgoing exchange where the shop is the receiver" do
            let!(:outgoing_exchange) {
              order_cycle.exchanges.create(sender: product.supplier,
                                           receiver: shop,
                                           incoming: false,
                                           variants: [variant])
            }

            it "is true" do
              expect(described_class).to be_in_open_and_upcoming_order_cycles(shop,
                                                                              schedule,
                                                                              variant)
            end
          end
        end

        context "if the variant is unrelated" do
          it "is false" do
            expect(described_class).to_not be_in_open_and_upcoming_order_cycles(shop,
                                                                                schedule,
                                                                                variant)
          end
        end
      end
    end
  end
end
