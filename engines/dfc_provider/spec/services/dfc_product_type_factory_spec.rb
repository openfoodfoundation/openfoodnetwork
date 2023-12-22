# frozen_string_literal: true

require_relative "../spec_helper"

describe DfcProductTypeFactory do
  describe ".for" do
    let(:dfc_id) {
      "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#drink"
    }

    it "assigns a top level product type" do
      drink = DfcLoader.connector.PRODUCT_TYPES.DRINK

      expect(described_class.for(dfc_id)).to eq drink
    end

    context "with second level product type" do
      let(:dfc_id) {
        "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#soft-drink"
      }

      it "assigns a second level product type" do
        soft_drink = DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK

        expect(described_class.for(dfc_id)).to eq soft_drink
      end
    end

    context "with leaf level product type" do
      let(:dfc_id) {
        "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#lemonade"
      }

      it "assigns a leaf level product type" do
        lemonade = DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK.LEMONADE

        expect(described_class.for(dfc_id)).to eq lemonade
      end
    end

    context "with non existing product type" do
      let(:dfc_id) { "other" }

      it "returns nil" do
        expect(described_class.for(dfc_id)).to be_nil
      end
    end
  end
end
