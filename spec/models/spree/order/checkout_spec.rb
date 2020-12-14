# frozen_string_literal: true

require 'spec_helper'

describe Spree::Order::Checkout do
  let(:order) { Spree::Order.new }

  context "with default state machine" do
    let(:transitions) do
      [
        { address: :delivery },
        { delivery: :payment },
        { payment: :complete },
        { delivery: :complete }
      ]
    end

    it "has the following transitions" do
      transitions.each do |transition|
        transition = Spree::Order.find_transition(from: transition.keys.first,
                                                  to: transition.values.first)
        expect(transition).to_not be_nil
      end
    end

    it "does not have a transition from delivery to confirm" do
      transition = Spree::Order.find_transition(from: :delivery, to: :confirm)
      expect(transition).to be_nil
    end

    it '.find_transition when contract was broken' do
      expect(Spree::Order.find_transition({ foo: :bar, baz: :dog })).to be_falsy
    end

    context "#checkout_steps" do
      context "when payment not required" do
        before { allow(order).to receive_messages payment_required?: false }
        specify do
          expect(order.checkout_steps).to eq %w(address delivery complete)
        end
      end

      context "when payment required" do
        before { allow(order).to receive_messages payment_required?: true }
        specify do
          expect(order.checkout_steps).to eq %w(address delivery payment complete)
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
      expect(lambda { order.next! }).to raise_error(StateMachines::InvalidTransition,
                                                    /#{Spree.t(:there_are_no_items_for_this_order)}/)
    end

    context "from address" do
      before do
        order.state = 'address'
        order.distributor = create(:distributor_enterprise)
        allow(order).to receive(:has_available_payment)
        order.shipments << create(:shipment)
        order.email = "user@example.com"
        order.save!
      end

      it "updates totals" do
        allow(order).to receive(:ensure_available_shipping_rates) { true }
        line_item = create(:line_item, price: 10, adjustment_total: 10)
        order.line_items << line_item
        tax_rate = create(:tax_rate, tax_category: line_item.tax_category, amount: 0.05)
        allow(Spree::TaxRate).to receive(:match) { [tax_rate] }
        create(:tax_adjustment, adjustable: line_item, source: tax_rate, order: order)
        order.email = "user@example.com"
        order.next!
        expect(order.adjustment_total).to eq 0.5
        expect(order.additional_tax_total).to eq 0.5
        expect(order.included_tax_total).to eq 0
        expect(order.total).to eq 10.5
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
          expect(order).to receive(:set_shipments_cost)
          order.next!
          expect(order.state).to eq 'payment'
        end
      end

      context "without payment required" do
        before do
          allow(order).to receive_messages payment_required?: false
        end

        it "transitions to complete" do
          order.next!
          expect(order.state).to eq "complete"
        end
      end

      context "correctly determining payment required based on shipping information" do
        let(:shipment) { create(:shipment) }

        before do
          # Needs to be set here because we're working with a persisted order object
          order.email = "test@example.com"
          order.save!
          order.shipments << shipment
        end

        context "with a shipment that has a price" do
          before do
            shipment.shipping_rates.first.update_column(:cost, 10)
          end

          it "transitions to payment" do
            order.next!
            expect(order.state).to eq "payment"
          end
        end

        context "with a shipment that is free" do
          before do
            shipment.shipping_rates.first.update_column(:cost, 0)
          end

          it "skips payment, transitions to complete" do
            order.next!
            expect(order.state).to eq "complete"
          end
        end
      end
    end

    context "from payment" do
      before do
        order.state = 'payment'
      end

      context "when payment is required" do
        before do
          allow(order).to receive_messages confirmation_required?: false
          allow(order).to receive_messages payment_required?: true
        end

        it "transitions to complete" do
          expect(order).to receive(:process_payments!).once.and_return true
          order.next!
          expect(order.state).to eq "complete"
        end
      end

      # Regression test for Spree #2028
      context "when payment is not required" do
        before do
          allow(order).to receive_messages payment_required?: false
        end

        it "does not call process payments" do
          expect(order).to_not receive(:process_payments!)
          order.next!
          expect(order.state).to eq "complete"
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
