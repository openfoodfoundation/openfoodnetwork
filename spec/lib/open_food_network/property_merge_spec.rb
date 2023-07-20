# frozen_string_literal: true

require 'spec_helper'

module OpenFoodNetwork
  describe PropertyMerge do
    let(:property) { create(:property, presentation: 'One') }
    let(:duplicate_property) { create(:property, presentation: 'One') }
    let(:different_property) { create(:property, presentation: 'Two') }

    describe "merging Spree::Properties" do
      it "merges properties" do
        merge = PropertyMerge.merge(
          [property],
          [duplicate_property, different_property]
        )
        expect(merge).to eq [property, different_property]
      end
    end

    describe "merging ProducerProperties and Spree::ProductProperties" do
      let(:product_property) { create(:product_property, property: property) }
      let(:duplicate_product_property) { create(:producer_property, property: duplicate_property) }
      let(:producer_property) { create(:producer_property, property: different_property) }

      it "merges properties" do
        merge = PropertyMerge.merge(
          [product_property],
          [duplicate_product_property, producer_property]
        )
        expect(merge).to eq [product_property, producer_property]
      end
    end
  end
end
