require 'spec_helper'

module Spree
  describe Price do
    let(:variant) { create(:variant) }
    let(:price) { variant.default_price }

    describe "callbacks" do
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

    context "when variant is soft-deleted" do
      before do
        variant.destroy
      end

      it "can access the variant" do
        expect(price.variant).to eq variant
      end
    end
  end
end
