# frozen_string_literal: true

RSpec.describe Orders::AddCartToOrderService do
  subject(:service) { described_class.new(cart:, order:) }

  let(:user) { create(:user) }
  let(:distributor) { create(:distributor_enterprise, allow_order_additions: true) }
  let(:variant) { create(:variant, price: 10, on_demand: false, on_hand: 5) }
  let(:order_cycle) {
    create(:simple_order_cycle, distributors: [distributor], variants: [variant])
  }
  let(:order) { create(:completed_order_with_totals, user:, distributor:, order_cycle:) }
  let(:cart) { create(:order, user:, distributor:, order_cycle:) }

  before do
    create(:line_item, order: cart, variant:, quantity: 2)
  end

  describe "#call" do
    it "adds the cart's items to the order, keeping its number" do
      number = order.number

      expect(service.call).to be true

      expect(order.reload.number).to eq number
      expect(order.find_line_item_by_variant(variant).quantity).to eq 2
      expect(order.line_items.count).to eq 2
    end

    it "raises the quantity when the order already has the same item" do
      order.contents.add(variant, 1, order.shipment)

      service.call

      expect(order.reload.find_line_item_by_variant(variant).quantity).to eq 3
    end

    it "takes the items from stock straight away" do
      expect { service.call }.to change { variant.reload.on_hand }.from(5).to(3)
    end

    it "empties the cart, keeping its shop and order cycle" do
      service.call

      expect(cart.reload.line_items).to be_empty
      expect(cart.distributor).to eq distributor
      expect(cart.order_cycle).to eq order_cycle
    end

    it "updates the order's total" do
      expect { service.call }.to change { order.reload.total }.by(20)
    end

    context "with a delivery fee of 5 per item" do
      let(:order) {
        create(:completed_order_with_fees, user:, distributor:, order_cycle:, shipping_fee: 5)
      }

      it "recalculates it on the order's one shipment instead of charging it again" do
        expect(order.ship_total).to eq 10 # 2 items

        service.call

        expect(order.reload.shipments.count).to eq 1
        expect(order.ship_total).to eq 20 # 4 items
      end
    end

    it "raises the amount due on an unpaid cash payment" do
      payment = create(:payment, order:, amount: order.total, state: "pending")

      service.call

      expect(payment.reload.amount).to eq order.reload.total
    end

    it "leaves a balance due on an order that was paid in full" do
      create(:payment, :completed, order:, amount: order.total)
      order.update_order!
      expect(order.payment_state).to eq "paid"

      service.call

      expect(order.reload.payment_state).to eq "balance_due"
    end

    context "with a shop price for the item", feature: :inventory do
      before { create(:variant_override, hub: distributor, variant:, price: 7) }

      it "adds the item at the shop's price" do
        service.call

        expect(order.reload.find_line_item_by_variant(variant).price).to eq 7
      end
    end

    context "when an item sold out after it was put in the cart" do
      before { variant.update!(on_hand: 1) }

      it "adds nothing and keeps the cart" do
        expect(service.call).to be false

        expect(service.error).to eq :insufficient_stock
        expect(order.reload.find_line_item_by_variant(variant)).to be_nil
        expect(cart.reload.line_items.count).to eq 1
        expect(variant.reload.on_hand).to eq 1
      end
    end

    context "when the shop doesn't allow items to be added" do
      let(:distributor) {
        create(:distributor_enterprise, allow_order_removals: true, allow_order_cancellation: true)
      }

      it "adds nothing" do
        expect(service.call).to be false

        expect(service.error).to eq :order_not_addable
        expect(order.reload.line_items.count).to eq 1
        expect(cart.reload.line_items.count).to eq 1
      end
    end

    context "when the order belongs to another customer" do
      let(:order) {
        create(:completed_order_with_totals, user: create(:user), distributor:, order_cycle:)
      }

      it "adds nothing" do
        expect(service.call).to be false

        expect(service.error).to eq :order_not_addable
        expect(order.reload.line_items.count).to eq 1
      end
    end

    context "when the order is from another order cycle" do
      let(:order) {
        create(:completed_order_with_totals, user:, distributor:,
                                             order_cycle: create(:simple_order_cycle,
                                                                 distributors: [distributor]))
      }

      it "adds nothing" do
        expect(service.call).to be false

        expect(service.error).to eq :order_not_addable
      end
    end

    context "when the order is a subscription order" do
      before { create(:proxy_order, order:) }

      it "adds nothing" do
        expect(service.call).to be false

        expect(service.error).to eq :order_not_addable
      end
    end

    context "when the cart is empty" do
      before { cart.line_items.destroy_all }

      it "adds nothing" do
        expect(service.call).to be false

        expect(service.error).to eq :empty_cart
      end
    end

    context "when the customer isn't logged in" do
      let(:cart) {
        create(:order, user: nil, email: "guest@example.com", distributor:, order_cycle:)
      }

      it "adds nothing" do
        expect(service.call).to be false

        expect(service.error).to eq :order_not_addable
      end
    end
  end
end
