# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe ProductTypeImporter do
  let(:drink) {
    DfcLoader.connector.PRODUCT_TYPES.DRINK
  }
  let(:soft_drink) {
    DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK
  }
  let(:lemonade) {
    DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK.LEMONADE
  }

  describe ".taxon" do
    it "finds a linked taxon" do
      create(:taxon, dfc_id: soft_drink.semanticId)
      lemonade_taxon = create(:taxon, dfc_id: lemonade.semanticId)
      expect(described_class.taxon(lemonade)).to eq lemonade_taxon
    end

    it "falls back to a broader taxon" do
      drink_taxon = create(:taxon, dfc_id: drink.semanticId)
      expect(described_class.taxon(lemonade)).to eq drink_taxon
    end

    it "returns random taxon when none can be found" do
      only_taxon = create(:taxon)
      expect(described_class.taxon(lemonade)).to eq only_taxon
    end

    it "queries the database only until it found a taxon" do
      soft_drink_taxon = create(:taxon, dfc_id: soft_drink.semanticId)

      expect {
        expect(described_class.taxon(lemonade)).to eq soft_drink_taxon
      }.to query_database [
        "Spree::Taxon Load", # query for lemonade, not found
        "Spree::Taxon Load", # query for soft drink, found
        # no query for drink
      ]
    end
  end

  describe ".list_broaders" do
    it "returns an empty array if no type is given" do
      list = described_class.list_broaders(nil)
      expect(list).to eq []
    end

    it "can return an empty list for top concepts" do
      list = described_class.list_broaders(drink)
      expect(list).to eq []
    end

    it "lists the broader concepts of a type" do
      list = described_class.list_broaders(soft_drink)
      expect(list).to eq [drink]
    end

    it "lists all the broader concepts to the top concepts" do
      list = described_class.list_broaders(lemonade)
      expect(list).to eq [soft_drink, drink]
    end
  end
end
