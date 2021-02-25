# frozen_string_literal: true

require 'spec_helper'

describe Api::CachedEnterpriseSerializer do
  let(:cached_enterprise_serializer) { described_class.new(enterprise) }
  let(:enterprise) { create(:enterprise) }

  describe '#supplied_properties' do
    let(:property) { create(:property, presentation: 'One') }
    let(:duplicate_property) { create(:property, presentation: 'One') }
    let(:different_property) { create(:property, presentation: 'Two') }

    before do
      product = create(:product, properties: [property])
      enterprise.supplied_products << product
    end

    context "when the enterprise is a producer" do
      let(:enterprise) do
        create(:enterprise,
               is_primary_producer: true,
               properties: [duplicate_property, different_property])
      end

      it "serializes combined product and producer properties without duplicates" do
        properties = cached_enterprise_serializer.supplied_properties
        expect(properties).to eq([property, different_property])
      end
    end

    context "when the enterprise is not a producer" do
      let(:enterprise) do
        create(:enterprise,
               is_primary_producer: false,
               properties: [duplicate_property, different_property])
      end

      it "does not serialize supplied properties" do
        properties = cached_enterprise_serializer.supplied_properties
        expect(properties).to eq([])
      end
    end
  end

  describe '#distributed_properties' do
    let(:cached_enterprise_serializer) { described_class.new(shop, options) }

    let(:shop) { create(:distributor_enterprise) }

    let(:options) { { data: enterprise_injection_data } }

    let(:property) { create(:property, presentation: 'One') }
    let(:duplicate_property) { create(:property, presentation: 'One') }
    let(:producer) { create(:supplier_enterprise, properties: [duplicate_property]) }

    before do
      product = create(:product, properties: [property])
      producer.supplied_products << product

      create(
        :simple_order_cycle,
        coordinator: shop,
        suppliers: [producer],
        distributors: [shop],
        variants: product.variants
      )
    end

    context 'when the enterprise is not an active distributor' do
      let(:enterprise_injection_data) do
        instance_double(OpenFoodNetwork::EnterpriseInjectionData, active_distributor_ids: [])
      end

      it 'does not serialize distributed properties' do
        properties = cached_enterprise_serializer.distributed_properties
        expect(properties).to eq []
      end
    end

    context 'when the enterprise is an active distributor' do
      let(:enterprise_injection_data) do
        instance_double(OpenFoodNetwork::EnterpriseInjectionData, active_distributor_ids: [shop.id])
      end

      it 'does not duplicate properties' do
        properties = cached_enterprise_serializer.distributed_properties
        expect(properties.map(&:presentation)).to eq([property.presentation])
      end

      it 'fetches producer properties' do
        distributed_producer_properties = cached_enterprise_serializer
          .distributed_producer_properties

        expect(distributed_producer_properties.map(&:presentation))
          .to eq(producer.producer_properties.map(&:property).map(&:presentation))
      end
    end
  end

  describe '#icon' do
    context "enterpise has a unrecognized category" do
      before do
        allow(enterprise).to receive(:category) { "unknown_category" }
      end

      it "returns the map producer icon" do
        expect(cached_enterprise_serializer.icon).to eq("/map_icons/map_001-producer-only.svg")
      end
    end

    context "enterpise has a nil category" do
      before do
        allow(enterprise).to receive(:category) { nil }
      end

      it "returns the map producer icon" do
        expect(cached_enterprise_serializer.icon).to eq("/map_icons/map_001-producer-only.svg")
      end
    end
  end
end
