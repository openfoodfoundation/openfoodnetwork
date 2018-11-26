require 'spec_helper'

describe Api::CachedEnterpriseSerializer do
  let(:cached_enterprise_serializer) { described_class.new(enterprise) }
  let(:enterprise) { create(:enterprise) }

  describe '#product_properties' do
    let(:property) { create(:property) }

    before do
      product = create(:product, properties: [property])
      enterprise.supplied_products << product
    end

    it 'returns the properties of the products supplied by the enterprise' do
      expect(cached_enterprise_serializer.product_properties).to eq([property])
    end
  end

  describe '#producer_properties' do
    let(:property) { create(:property) }

    before { enterprise.properties << property }

    it 'returns the properties of the enterprise' do
      expect(cached_enterprise_serializer.producer_properties).to eq([property])
    end
  end

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
      merge = cached_enterprise_serializer.supplied_properties
      expect(merge).to eq([property, different_property])
    end
  end
end
