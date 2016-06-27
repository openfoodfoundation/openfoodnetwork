require 'spec_helper'

module Spree
  describe Property do
    describe "scopes" do
      describe ".applied_by" do
        let(:producer) { create(:supplier_enterprise) }
        let(:producer_other) { create(:supplier_enterprise) }
        let(:product) { create(:simple_product, supplier: producer) }
        let(:product_other_producer) { create(:simple_product, supplier: producer_other) }
        let(:product_other_property) { create(:simple_product, supplier: producer) }
        let(:property) { product.properties.last }
        let(:property_other) { product_other_producer.properties.last }

        before do
          product.set_property                'Organic', 'NASAA 12345'
          product_other_property.set_property 'Organic', 'NASAA 12345'
          product_other_producer.set_property 'Biodynamic', 'ASDF 1234'
        end

        it "returns properties applied to supplied products" do
          expect(Spree::Property.applied_by(producer)).to eq [property]
        end

        it "doesn't return properties not applied" do
          expect(Spree::Property.applied_by(producer)).not_to include property_other
        end

        it "doesn't return duplicates" do
          expect(Spree::Property.applied_by(producer).to_a.count).to eq 1
        end
      end
    end

    describe "callbacks" do
      let(:property) { product_property.property }
      let(:product) { product_property.product }
      let(:product_property) { create(:product_property) }

      it "refreshes the products cache on save" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(product)
        property.name = 'asdf'
        property.save
      end
    end
  end
end
