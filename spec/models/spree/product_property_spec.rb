require 'spec_helper'

module Spree
  describe ProductProperty do
    describe "callbacks" do
      let(:product) { product_property.product }
      let(:product_property) { create(:product_property) }

      it "refreshes the products cache on save, via Product" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(product)
        product_property.value = 123
        product_property.save
      end

      it "refreshes the products cache on destroy" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(product)
        product_property.destroy
      end
    end
  end
end
