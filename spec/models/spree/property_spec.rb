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

      describe ".currently_sold_by and .ever_sold_by" do
        let!(:shop) { create(:distributor_enterprise) }
        let!(:shop_other) { create(:distributor_enterprise) }
        let!(:product) { create(:simple_product) }
        let!(:product_other_ex) { create(:simple_product) }
        let!(:product_no_oc) { create(:simple_product) }
        let!(:oc) { create(:simple_order_cycle, distributors: [shop], variants: [product.variants.first]) }
        let!(:exchange_other_shop) { create(:exchange, order_cycle: oc, sender: oc.coordinator, receiver: shop_other, variants: [product_other_ex.variants.first]) }
        let(:property) { product.properties.last }
        let(:property_other_ex) { product_other_ex.properties.last }
        let(:property_no_oc) { product_no_oc.properties.last }

        before do
          product.set_property 'Organic', 'NASAA 12345'
          product_other_ex.set_property 'Biodynamic', 'ASDF 12345'
          product_no_oc.set_property 'Shiny', 'Very'
        end

        it "returns the property" do
          expect(Property.currently_sold_by(shop)).to eq [property]
          expect(Property.ever_sold_by(shop)).to eq [property]
        end

        it "doesn't return the property from another exchange" do
          expect(Property.currently_sold_by(shop)).not_to include property_other_ex
          expect(Property.ever_sold_by(shop)).not_to include property_other_ex
        end

        it "doesn't return the property with no order cycle" do
          expect(Property.currently_sold_by(shop)).not_to include property_no_oc
          expect(Property.ever_sold_by(shop)).not_to include property_no_oc
        end

        describe "closed order cyces" do
          let!(:product_closed_oc) { create(:simple_product) }
          let!(:oc_closed) { create(:closed_order_cycle, distributors: [shop], variants: [product_closed_oc.variants.first]) }
          let(:property_closed_oc) { product_closed_oc.properties.last }

          before { product_closed_oc.set_property 'Spiffy', 'Ooh yeah' }

          it "doesn't return the property for .currently_sold_by" do
            expect(Property.currently_sold_by(shop)).not_to include property_closed_oc
          end

          it "returns the property for .ever_sold_by" do
            expect(Property.ever_sold_by(shop)).to include property_closed_oc
          end
        end

        context "with another product in the order cycle" do
          let!(:product2) { create(:simple_product) }
          let!(:oc) { create(:simple_order_cycle, distributors: [shop], variants: [product.variants.first, product2.variants.first]) }

          before do
            product2.set_property 'Organic', 'NASAA 12345'
          end

          it "doesn't return duplicates" do
            expect(Property.currently_sold_by(shop).to_a.count).to eq 1
            expect(Property.ever_sold_by(shop).to_a.count).to eq 1
          end
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
