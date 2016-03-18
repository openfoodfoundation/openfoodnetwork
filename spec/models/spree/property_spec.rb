require 'spec_helper'

module Spree
  describe Property do
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
