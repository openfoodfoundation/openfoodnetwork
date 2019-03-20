require 'spec_helper'

describe Spree::Order do
  describe 'event :restart_checkout' do
    let(:order) { create(:order) }

    context 'when the order is not complete' do
      before { allow(order).to receive(:completed?) { false } }

      it 'does transition to cart state' do
        expect(order.state).to eq('cart')
      end
    end

    context 'when the order is complete' do
      before { allow(order).to receive(:completed?) { true } }

      it 'raises' do
        expect { order.restart_checkout! }
          .to raise_error(
            StateMachine::InvalidTransition,
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

      # If the shipping category package splitter is enabled,
      #   an order with products with two shipping categories will be split into two shipments
      #   and the spec will fail with a unique constraint error on index_spree_shipments_on_order_id
      order.next
      order.next
      expect(order.state).to eq "delivery"
    end
  end
end
