require "spec_helper"

describe ExchangeProductsRenderer do
  let(:order_cycle) { create(:order_cycle) }
  let(:coordinator) { order_cycle.coordinator }
  let(:renderer) { described_class.new(order_cycle, coordinator.owner) }

  describe "#exchange_products" do
    describe "for an incoming exchange" do
      it "loads products" do
        exchange = order_cycle.exchanges.incoming.first
        products = renderer.exchange_products(true, exchange.sender)

        expect(products.first.supplier.name).to eq exchange.variants.first.product.supplier.name
      end
    end

    describe "for an outgoing exchange" do
      it "loads products" do
        exchange = order_cycle.exchanges.outgoing.first
        products = renderer.exchange_products(false, exchange.receiver)

        suppliers = [exchange.variants[0].product.supplier.name, exchange.variants[1].product.supplier.name]
        expect(suppliers).to include products.first.supplier.name
        expect(suppliers).to include products.second.supplier.name
      end
    end
  end
end
