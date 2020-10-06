require 'spec_helper'

module Spree
  describe Classification do
    let(:product) { build_stubbed(:simple_product) }
    let(:taxon) { build_stubbed(:taxon) }

    it "won't destroy if classification is the primary taxon" do
      classification = Classification.new(taxon: taxon, product: product)
      product.primary_taxon = taxon
      expect(classification.destroy).to be false
      expect(classification.errors.messages[:base]).to eq(["Taxon #{taxon.name} is the primary taxon of #{product.name} and cannot be deleted"])
    end
  end
end
