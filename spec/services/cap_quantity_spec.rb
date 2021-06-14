# frozen_string_literal: true

require 'spec_helper'

describe CapQuantity do
  describe "checking that line items are available to purchase" do
    let(:order_cycle) { create(:simple_order_cycle) }
    let(:shop) { order_cycle.coordinator }
    let(:order) { create(:order, order_cycle: order_cycle, distributor: shop) }
    let(:ex) { create(:exchange, order_cycle: order_cycle, sender: shop, receiver: shop, incoming: false) }
    let(:variant1) { create(:variant, on_hand: 5) }
    let(:variant2) { create(:variant, on_hand: 5) }
    let(:variant3) { create(:variant, on_hand: 5) }
    let!(:line_item1) { create(:line_item, order: order, variant: variant1, quantity: 3) }
    let!(:line_item2) { create(:line_item, order: order, variant: variant2, quantity: 3) }
    let!(:line_item3) { create(:line_item, order: order, variant: variant3, quantity: 3) }

    context "when all items are available from the order cycle" do
      before { [variant1, variant2, variant3].each { |v| ex.variants << v } }

      context "and insufficient stock exists to fulfil the order for some items" do
        before do
          variant1.update_attribute(:on_hand, 5)
          variant2.update_attribute(:on_hand, 2)
          variant3.update_attribute(:on_hand, 0)
        end

        it "caps quantity at the stock level for stock-limited items, and reports the change" do
          changes = CapQuantity.new(order.reload).call

          expect(line_item1.reload.quantity).to be 3 # not capped
          expect(line_item2.reload.quantity).to be 2 # capped
          expect(line_item3.reload.quantity).to be 0 # capped
          expect(changes[line_item1.id]).to be nil
          expect(changes[line_item2.id]).to be 3
          expect(changes[line_item3.id]).to be 3
        end
      end
    end

    context "and some items are not available from the order cycle" do
      before { [variant2, variant3].each { |v| ex.variants << v } }

      context "and insufficient stock exists to fulfil the order for some items" do
        before do
          variant1.update_attribute(:on_hand, 5)
          variant2.update_attribute(:on_hand, 2)
          variant3.update_attribute(:on_hand, 0)
        end

        it "sets quantity to 0 for unavailable items, and reports the change" do
          changes = CapQuantity.new(order.reload).call

          expect(line_item1.reload.quantity).to be 0 # unavailable
          expect(line_item2.reload.quantity).to be 2 # capped
          expect(line_item3.reload.quantity).to be 0 # capped
          expect(changes[line_item1.id]).to be 3
          expect(changes[line_item2.id]).to be 3
          expect(changes[line_item3.id]).to be 3
        end

        context "and the order has been placed" do
          before do
            allow(order).to receive(:ensure_available_shipping_rates) { true }
            allow(order).to receive(:process_each_payment) { true }

            order.create_proposed_shipments
          end

          it "removes the unavailable items from the shipment" do
            expect { CapQuantity.new(order.reload).call }
              .to change { order.reload.shipment.manifest.size }.from(2).to(1)
          end
        end
      end
    end
  end
end
