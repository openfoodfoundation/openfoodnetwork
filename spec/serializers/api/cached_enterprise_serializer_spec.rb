require 'spec_helper'

describe Api::CachedEnterpriseSerializer do
  let(:cached_enterprise_serializer) { described_class.new(enterprise) }
  let(:enterprise) { create(:enterprise) }

  describe '#supplied_properties' do
    let(:property) { create(:property, presentation: 'One') }
    let(:duplicate_property) { create(:property, presentation: 'One') }
    let(:different_property) { create(:property, presentation: 'Two') }

    let(:enterprise) do
      create(:enterprise, properties: [duplicate_property, different_property])
    end

    before do
      product = create(:product, properties: [property])
      enterprise.supplied_products << product
    end

    it "removes duplicate product and producer properties" do
      properties = cached_enterprise_serializer.supplied_properties
      expect(properties).to eq([property, different_property])
    end
  end

  describe '#distributed_properties' do
    let(:cached_enterprise_serializer) { described_class.new(shop, options) }

    let(:enterprise_injection_data) do
      instance_double(OpenFoodNetwork::EnterpriseInjectionData, active_distributors: [])
    end
    let(:options) { { data: enterprise_injection_data } }
    let(:shop) { create(:distributor_enterprise, name: 'Distributor') }

    let(:property) { create(:property, presentation: 'One') }

    before do
      producer = create(:supplier_enterprise, name: 'Supplier')
      product = create(:product, supplier: producer, properties: [property])

      order_cycle = build(:simple_order_cycle, coordinator: shop)

      incoming_exchange = build(:exchange, sender: producer, receiver: shop, incoming: true)
      outgoing_exchange = build(:exchange, sender: shop, receiver: shop, incoming: false)
      outgoing_exchange.variants << product.variants.first

      order_cycle.exchanges << incoming_exchange
      order_cycle.exchanges << outgoing_exchange

      order_cycle.save
    end

    it 'does not duplicate properties' do
      properties = cached_enterprise_serializer.distributed_properties
      expect(properties).to eq([property])
    end
  end
end
