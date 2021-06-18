# frozen_string_literal: true

require 'spec_helper'

describe OrderFactory do
  let(:variant1) { create(:variant, price: 5.0) }
  let(:variant2) { create(:variant, price: 7.0) }
  let(:user) { create(:user) }
  let(:customer) { create(:customer, user: user) }
  let(:shop) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle) }
  let!(:other_shipping_method_a) { create(:shipping_method) }
  let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
  let!(:other_shipping_method_b) { create(:shipping_method) }
  let(:payment_method) { create(:payment_method) }
  let(:ship_address) { create(:address) }
  let(:bill_address) { create(:address) }
  let(:opts) { {} }
  let(:factory) { OrderFactory.new(attrs, opts) }
  let(:order) { factory.create }

  describe "create" do
    let(:attrs) do
      attrs = {}
      attrs[:line_items] =
        [{ variant_id: variant1.id, quantity: 2 }, { variant_id: variant2.id, quantity: 4 }]
      attrs[:customer_id] = customer.id
      attrs[:distributor_id] = shop.id
      attrs[:order_cycle_id] = order_cycle.id
      attrs[:shipping_method_id] = shipping_method.id
      attrs[:payment_method_id] = payment_method.id
      attrs[:bill_address_attributes] = bill_address.attributes.except("id")
      attrs[:ship_address_attributes] = ship_address.attributes.except("id")
      attrs
    end

    it "builds a new order based on the provided attributes" do
      expect_new_order
      expect(order.line_items.count).to eq 2
      expect(order.customer).to eq customer
      expect(order.user).to eq user
      expect(order.distributor).to eq shop
      expect(order.order_cycle).to eq order_cycle
      expect(order.shipments.first.shipping_method).to eq shipping_method
      expect(order.payments.first.payment_method).to eq payment_method
      expect(order.bill_address).to eq bill_address
      expect(order.ship_address).to eq ship_address
      expect(order.total).to eq 38.0
      expect(order.complete?).to be false
    end

    it "retains address, delivery, and payment attributes until completion of the order" do
      OrderWorkflow.new(order).complete

      order.reload

      expect(order.customer).to eq customer
      expect(order.shipping_method).to eq shipping_method
      expect(order.payments.first.payment_method).to eq payment_method
      expect(order.bill_address).to eq bill_address
      expect(order.ship_address).to eq ship_address
      expect(order.total).to eq 38.0
    end

    context "when the customer does not have a user associated with it" do
      before { customer.update_attribute(:user_id, nil) }

      it "initialises the order without a user_id" do
        expect_new_order
        expect(order.user).to be nil
      end
    end

    context "when requested quantity is greater than available stock" do
      context "when no override is present" do
        before do
          variant1.update_attribute(:on_hand, 2)
          attrs[:line_items].first[:quantity] = 5
        end

        context "when skip_stock_check is not requested" do
          it "initialises the order but limits stock to the available amount" do
            expect_new_order
            expect(variant1_line_item.quantity).to eq 2
          end

          context "when variant is on_demand" do
            before { variant1.update_attribute(:on_demand, true) }

            it "initialises the order with the requested quantity regardless of stock" do
              expect_new_order
              expect(variant1_line_item.quantity).to eq 5
            end
          end
        end

        context "when skip_stock_check is requested" do
          let(:opts) { { skip_stock_check: true } }

          it "initialises the order with the requested quantity regardless" do
            expect_new_order
            expect(variant1_line_item.quantity).to eq 5
          end
        end
      end

      context "when an override is present" do
        let!(:override) {
          create(:variant_override, hub_id: shop.id, variant_id: variant1.id, count_on_hand: 3)
        }
        before { attrs[:line_items].first[:quantity] = 6 }

        context "when skip_stock_check is not requested" do
          it "initialised the order but limits stock to the available amount" do
            expect_new_order
            expect(variant1_line_item.quantity).to eq 3
          end
        end

        context "when skip_stock_check is requested" do
          let(:opts) { { skip_stock_check: true } }

          it "initialises the order with the requested quantity regardless" do
            expect_new_order
            expect(variant1_line_item.quantity).to eq 6
          end
        end
      end
    end

    describe "determining the price for line items" do
      context "when no override is present" do
        it "uses the price from the variant" do
          expect_new_order
          expect(variant1_line_item.price).to eq 5.0
          expect(order.total).to eq 38.0
        end
      end

      context "when an override is present" do
        let!(:override) {
          create(:variant_override, hub_id: shop.id, variant_id: variant1.id, price: 3.0)
        }

        it "uses the price from the override" do
          expect_new_order
          expect(variant1_line_item.price).to eq 3.0
          expect(order.total).to eq 34.0
        end
      end
    end

    def expect_new_order
      expect{ order }.to change{ Spree::Order.count }.by(1)
      expect(order).to be_a Spree::Order
    end

    def variant1_line_item
      order.line_items.find_by(variant_id: variant1.id)
    end
  end
end
