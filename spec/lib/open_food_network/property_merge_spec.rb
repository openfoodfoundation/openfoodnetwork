require 'spec_helper'

module OpenFoodNetwork
  describe PropertyMerge do
    let(:p1a) { create(:property, presentation: 'One') }
    let(:p1b) { create(:property, presentation: 'One') }
    let(:p2)  { create(:property, presentation: 'Two') }

    describe "merging Spree::Properties" do
      it "merges properties" do
        expect(PropertyMerge.merge([p1a], [p1b, p2])).to eq [p1a, p2]
      end
    end

    describe "merging ProducerProperties and Spree::ProductProperties" do
      let(:pp1a) { create(:product_property,  property: p1a) }
      let(:pp1b) { create(:producer_property, property: p1b) }
      let(:pp2)  { create(:producer_property, property: p2) }

      it "merges properties" do
        expect(PropertyMerge.merge([pp1a], [pp1b, pp2])).to eq [pp1a, pp2]
      end
    end
  end
end
