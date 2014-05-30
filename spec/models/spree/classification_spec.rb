require 'spec_helper'

module Spree
  describe Classification do
    let(:product) { create(:simple_product) }
    let(:taxon) { create(:taxon) }
    let(:classification) { create(:classification, taxon: taxon, product: product) }

    it "won't destroy if classification is the primary taxon" do
      product.primary_taxon = taxon
      classification.destroy.should be_false
      classification.errors.messages[:base].should == ["Taxon #{taxon.name} is the primary taxon of #{product.name} and cannot be deleted"]
    end
  end
end
