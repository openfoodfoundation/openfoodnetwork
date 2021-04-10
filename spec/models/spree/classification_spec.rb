# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe Classification do
    let(:product) { create(:simple_product) }
    let(:taxon) { create(:taxon) }

    it "won't destroy if classification is the primary taxon" do
      classification = Classification.create(taxon: taxon, product: product)
      product.update(primary_taxon: taxon)

      expect(classification.destroy).to be false
      expect(classification.errors.messages[:base]).to eq(["Taxon #{taxon.name} is the primary taxon of #{product.name} and cannot be deleted"])
      expect(classification.reload).to be
    end
  end
end
