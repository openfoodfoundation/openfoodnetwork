require 'spec_helper'

module Spree
  describe Classification do
    let!(:product) { create(:simple_product) }
    let!(:taxon) { create(:taxon) }
    let(:classification) { create(:classification, taxon: taxon, product: product) }

    it "won't destroy if classification is the primary taxon" do
      product.primary_taxon = taxon
      classification.destroy.should be false
      classification.errors.messages[:base].should == ["Taxon #{taxon.name} is the primary taxon of #{product.name} and cannot be deleted"]
    end

    describe "callbacks" do
      it "refreshes the products cache on save" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(product)
        classification
      end

      it "refreshes the products cache on destroy" do
        classification
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(product)
        classification.destroy
      end
    end
  end
end
