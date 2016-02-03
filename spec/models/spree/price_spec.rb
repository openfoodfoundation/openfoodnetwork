require 'spec_helper'

module Spree
  describe Price do
    describe "callbacks" do
      let(:variant) { create(:variant) }
      let(:price) { variant.default_price }

      it "refreshes the products cache on change" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:variant_changed).with(variant)
        price.amount = 123
        price.save
      end

      it "refreshes the products cache on destroy" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:variant_changed).with(variant)
        price.destroy
      end
    end
  end
end
