# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe SuppliedProductBuilder do
  include FileHelper

  subject(:builder) { described_class }
  let(:variant) {
    create(:variant, id: 5, product: spree_product, primary_taxon: taxon, supplier:)
  }
  let(:spree_product) {
    create(:product, id: 6)
  }
  let(:supplier) {
    create(:supplier_enterprise, id: 7)
  }
  let(:taxon) {
    build(
      :taxon,
      name: "Soft Drink",
      dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#soft-drink"
    )
  }

  describe ".supplied_product" do
    it "assigns a semantic id" do
      product = builder.supplied_product(variant)

      expect(product.semanticId).to eq(
        "http://test.host/api/dfc/enterprises/7/supplied_products/5"
      )
    end

    it "assigns a quantity" do
      product = builder.supplied_product(variant)

      expect(product.quantity.value).to eq 1.0
      expect(product.quantity.unit.semanticId).to eq "dfc-m:Gram"
    end

    it "assigns the product name by default" do
      variant.product.name = "Apple"
      product = builder.supplied_product(variant)

      expect(product.name).to match /Apple/
    end

    it "assigns the variant name if present" do
      variant.product.name = "Apple"
      variant.display_name = "Granny Smith"
      product = builder.supplied_product(variant)

      expect(product.name).to match /Apple - Granny Smith/
    end

    context "product_type mapping" do
      subject(:product) { builder.supplied_product(variant) }

      it "assigns a product type" do
        soft_drink = DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK

        expect(product.productType).to eq soft_drink
      end
    end

    it "assigns an image_url type" do
      Spree::Image.create!(
        attachment: white_logo_file,
        viewable_id: variant.product.id,
        viewable_type: 'Spree::Product'
      )
      product = builder.supplied_product(variant)

      expect(product.image).to eq variant.product.image.url(:product)
    end

    it "assigns the product uri" do
      product = builder.supplied_product(variant)

      expect(product.spree_product_uri).to eq(
        "http://test.host/api/dfc/enterprises/7?spree_product_id=6"
      )
    end
  end
end
