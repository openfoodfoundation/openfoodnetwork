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

      # Do not refresh on price destruction - this (only?) happens when variant is destroyed,
      # and in that case the variant will take responsibility for refreshing the cache

      it "does not refresh the cache when variant is not set" do
        # Creates a price without the back link to variant
        create(:product, master: create(:variant))
        expect(OpenFoodNetwork::ProductsCache).to receive(:variant_changed).never
      end
    end
  end
end
