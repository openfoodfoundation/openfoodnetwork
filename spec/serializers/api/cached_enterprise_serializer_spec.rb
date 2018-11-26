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

    describe "merging Spree::Properties" do
      it "merges properties" do
        allow(cached_enterprise_serializer)
          .to receive(:product_properties) { [property] }
        allow(cached_enterprise_serializer)
          .to receive(:producer_properties) { [duplicate_property, different_property] }

        merge = cached_enterprise_serializer.supplied_properties
        expect(merge).to eq([property, different_property])
      end
    end

    describe "merging ProducerProperties and Spree::ProductProperties" do
      let(:product_property) { create(:product_property,  property: property) }
      let(:duplicate_product_property) { create(:producer_property, property: duplicate_property) }
      let(:producer_property) { create(:producer_property, property: different_property) }

      it "merges properties" do
        allow(cached_enterprise_serializer)
          .to receive(:product_properties) { [product_property] }
        allow(cached_enterprise_serializer)
          .to receive(:producer_properties) { [duplicate_product_property, producer_property] }

        merge = cached_enterprise_serializer.supplied_properties
        expect(merge).to eq([product_property, producer_property])
      end
    end
  end
end
