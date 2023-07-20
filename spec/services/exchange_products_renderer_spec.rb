# frozen_string_literal: true

require "spec_helper"

describe ExchangeProductsRenderer do
  let(:order_cycle) { create(:order_cycle) }
  let(:coordinator) { order_cycle.coordinator }
  let(:renderer) { described_class.new(order_cycle, coordinator.owner) }

  describe "#exchange_products" do
    describe "for an incoming exchange" do
      let(:exchange) { order_cycle.exchanges.incoming.first }

      it "loads products" do
        products = renderer.exchange_products(true, exchange.sender)

        expect(products.first.supplier.name).to eq exchange.variants.first.product.supplier.name
      end

      it "loads products in order" do
        products = renderer.exchange_products(true, exchange.sender)
        sorted_products_names = products.map(&:name).sort

        expect(products.map(&:name)).to eq(sorted_products_names)
      end
    end

    describe "for an outgoing exchange" do
      let(:exchange) { order_cycle.exchanges.outgoing.first }

      it "loads products" do
        products = renderer.exchange_products(false, exchange.receiver)

        suppliers = [exchange.variants[0].product.supplier.name,
                     exchange.variants[1].product.supplier.name]
        expect(suppliers).to include products.first.supplier.name
        expect(suppliers).to include products.second.supplier.name
      end

      it "loads products in order" do
        products = renderer.exchange_products(false, exchange.receiver)
        sorted_products_names = products.map(&:name).sort

        expect(products.map(&:name)).to eq(sorted_products_names)
      end

      context "showing products from coordinator inventory only" do
        before {
          order_cycle.update prefers_product_selection_from_coordinator_inventory_only: true
        }

        it "loads no products if there are no products from the coordinator inventory" do
          products = renderer.exchange_products(false, exchange.receiver)

          expect(products).to be_empty
        end

        it "loads products from the coordinator inventory" do
          # Add variant already in the exchange to the coordinator's inventory
          exchange.variants.first.inventory_items = [create(:inventory_item,
                                                            enterprise: order_cycle.coordinator)]

          products = renderer.exchange_products(false, exchange.receiver)

          expect(products).to eq [exchange.variants.first.product]
        end
      end
    end
  end

  describe "#exchange_variants" do
    describe "for an incoming exchange" do
      it "loads variants" do
        exchange = order_cycle.exchanges.incoming.first
        variants = renderer.exchange_variants(true, exchange.sender)

        expect(variants.first.product.supplier.name)
          .to eq exchange.variants.first.product.supplier.name
      end

      describe "when OC is showing only the coordinators inventory" do
        let(:exchange_with_visible_variant) { order_cycle.exchanges.incoming.last }
        let(:exchange_with_hidden_variant) { order_cycle.exchanges.incoming.first }
        let!(:visible_inventory_item) {
          create(:inventory_item, enterprise: order_cycle.coordinator,
                                  variant: exchange_with_visible_variant.variants.first,
                                  visible: true)
        }
        let!(:hidden_inventory_item) {
          create(:inventory_item, enterprise: order_cycle.coordinator,
                                  variant: exchange_with_hidden_variant.variants.first,
                                  visible: false)
        }

        before do
          order_cycle.prefers_product_selection_from_coordinator_inventory_only = true
        end

        it "renders visible inventory variants" do
          variants = renderer.exchange_variants(true, exchange_with_visible_variant.sender)

          expect(variants.size).to eq 1
        end

        it "does not render hidden inventory variants" do
          variants = renderer.exchange_variants(true, exchange_with_hidden_variant.sender)

          expect(variants.size).to eq 0
        end
      end
    end
  end
end
