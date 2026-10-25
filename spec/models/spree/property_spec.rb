# frozen_string_literal: true

RSpec.describe Spree::Property do
  describe ".distributed_by" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:producer) { create(:supplier_enterprise) }
    let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
    let(:outgoing_exchange) { order_cycle.exchanges.to_enterprises(distributor).outgoing.first }
    let(:product_property) { create(:property, presentation: "Organic") }
    let(:producer_property) { create(:property, presentation: "Bee-Friendly") }
    let(:product) { create(:product, enterprise_id: producer.id, properties: [product_property]) }

    before do
      create(:producer_property, producer_id: producer.id, property: producer_property)
    end

    it "returns properties of distributed products and of their producers" do
      outgoing_exchange.variants << product.variants.first

      expect(described_class.distributed_by(distributor))
        .to contain_exactly(product_property, producer_property)
    end

    it "includes products of closed order cycles" do
      closed_order_cycle = create(:closed_order_cycle, distributors: [distributor])
      closed_order_cycle.exchanges.to_enterprises(distributor).outgoing.first
        .variants << product.variants.first

      expect(described_class.distributed_by(distributor))
        .to contain_exactly(product_property, producer_property)
    end

    it "excludes producer properties of products that don't inherit properties" do
      product.update!(inherits_properties: false)
      outgoing_exchange.variants << product.variants.first

      expect(described_class.distributed_by(distributor)).to contain_exactly(product_property)
    end

    it "returns a property once when it is both a product and a producer property" do
      product.properties << producer_property
      outgoing_exchange.variants << product.variants.first

      expect(described_class.distributed_by(distributor).to_a)
        .to contain_exactly(product_property, producer_property)
    end

    it "excludes products distributed by other shops" do
      other_distributor = create(:distributor_enterprise)
      other_order_cycle = create(:simple_order_cycle, distributors: [other_distributor])
      other_order_cycle.exchanges.to_enterprises(other_distributor).outgoing.first
        .variants << product.variants.first

      expect(described_class.distributed_by(distributor)).to be_empty
    end

    it "excludes products only coming into the order cycle" do
      incoming_exchange = create(:exchange, order_cycle:, sender: producer,
                                            receiver: order_cycle.coordinator, incoming: true)
      incoming_exchange.variants << product.variants.first

      expect(described_class.distributed_by(distributor)).to be_empty
    end
  end
end
