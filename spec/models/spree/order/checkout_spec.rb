# frozen_string_literal: true

require 'spec_helper'

describe Spree::Order::Checkout do
  let(:order) { Spree::Order.new }

  context "with default state machine" do
    context "#checkout_steps" do
      context "when payment not required" do
        before { allow(order).to receive_messages payment_required?: false }
        specify do
          expect(order.checkout_steps).to eq %w(address delivery confirmation complete)
        end
      end

      context "when payment required" do
        before { allow(order).to receive_messages payment_required?: true }
        specify do
          expect(order.checkout_steps).to eq %w(address delivery payment confirmation complete)
        end
      end
    end

    it "starts out at cart" do
      expect(order.state).to eq "cart"
    end

    it "transitions to address" do
      order.line_items << FactoryBot.create(:line_item)
      order.email = "user@example.com"
      order.next!
      expect(order.state).to eq "address"
    end

    it "cannot transition to address without any line items" do
      expect(order.line_items).to be_blank
      expect(lambda { order.next! })
        .to raise_error(StateMachines::InvalidTransition,
                        /#{Spree.t(:there_are_no_items_for_this_order)}/)
    end

    context "from address" do
      before do
        order.state = 'address'
        order.shipments << create(:shipment)
        order.distributor = build(:distributor_enterprise)
        order.email = "user@example.com"
        order.save!
      end

      it "transitions to delivery" do
        allow(order).to receive_messages(ensure_available_shipping_rates: true)
        order.next!
        expect(order.state).to eq "delivery"
      end

      context "cannot transition to delivery" do
        context "if there are no shipping rates for any shipment" do
          specify do
            transition = lambda { order.next! }
            expect(transition).to raise_error(StateMachines::InvalidTransition,
                                              /#{Spree.t(:items_cannot_be_shipped)}/)
          end
        end
      end
    end

    context "from delivery" do
      before do
        order.state = 'delivery'
      end

      context "with payment required" do
        before do
          allow(order).to receive_messages payment_required?: true
        end

        it "transitions to payment" do
          order.next!
          expect(order.state).to eq 'payment'
        end
      end

      context "without payment required" do
        before do
          allow(order).to receive_messages payment_required?: false
        end

        it "transitions to confirmation" do
          order.next!
          expect(order.state).to eq 'confirmation'
        end
      end
    end
  end

  describe 'event :restart_checkout' do
    let(:order) { build_stubbed(:order) }

    context 'when the order is not complete' do
      before { allow(order).to receive(:completed?) { false } }

      it 'transitions to cart state' do
        expect(order.state).to eq('cart')
      end
    end

    context 'when the order is complete' do
      before { allow(order).to receive(:completed?) { true } }

      it 'raises' do
        expect { order.restart_checkout! }
          .to raise_error(
            StateMachines::InvalidTransition,
            /Cannot transition state via :restart_checkout/
          )
      end
    end
  end

  describe "order with products with different shipping categories" do
    let(:order) { create(:order_with_totals_and_distribution, ship_address: create(:address) ) }
    let(:shipping_method) { create(:shipping_method, distributors: [order.distributor]) }
    let(:other_shipping_category) { create(:shipping_category) }
    let(:other_product) { create(:product, shipping_category: other_shipping_category ) }
    let(:other_variant) { other_product.variants.first }

    before do
      order.order_cycle = create(:simple_order_cycle,
                                 distributors: [order.distributor],
                                 variants: [order.line_items.first.variant, other_variant])
      order.line_items << create(:line_item, order: order, variant: other_variant)
    end

    it "can progress to delivery" do
      shipping_method.shipping_categories << other_shipping_category

      order.next
      order.next
      expect(order.state).to eq "delivery"
    end
  end
end
