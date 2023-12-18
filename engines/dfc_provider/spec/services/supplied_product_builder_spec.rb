# frozen_string_literal: true

require_relative "../spec_helper"

describe SuppliedProductBuilder do
  include FileHelper

  subject(:builder) { described_class }
  let(:variant) {
    build(:variant, id: 5).tap do |v|
      v.product.supplier_id = 7
      v.product.primary_taxon = taxon
    end
  }
  let(:taxon) {
    build(
      :taxon,
      name: "Drink",
      dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#drink"
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

      expect(product.name).to eq "Apple"
    end

    it "assigns the variant name if present" do
      variant.product.name = "Apple"
      variant.display_name = "Granny Smith"
      product = builder.supplied_product(variant)

      expect(product.name).to eq "Apple - Granny Smith"
    end

    context "product_type mapping" do
      subject(:product) { builder.supplied_product(variant) }

      it "assigns a top level product type" do
        drink = DfcLoader.connector.PRODUCT_TYPES.DRINK

        expect(product.productType).to eq drink
      end

      context "with second level product type" do
        let(:taxon) {
          build(
            :taxon,
            name: "Soft Drink",
            dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#soft-drink"
          )
        }

        it "assigns a second level product type" do
          soft_drink = DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK

          expect(product.productType).to eq soft_drink
        end
      end

      context "with leaf level product type" do
        let(:taxon) {
          build(
            :taxon,
            name: "Lemonade",
            dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#lemonade"
          )
        }

        it "assigns a leaf level product type" do
          lemonade = DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK.LEMONADE

          expect(product.productType).to eq lemonade
        end
      end

      context "with non existing product type" do
        let(:taxon) { build(:taxon, name: "other", dfc_id: "other") }

        it "returns nil" do
          expect(product.productType).to be_nil
        end
      end

      context "when no taxon set" do
        let(:taxon) { nil }

        it "returns nil" do
          expect(product.productType).to be_nil
        end
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
  end

  describe ".import_product" do
    let(:supplied_product) do
      DataFoodConsortium::Connector::SuppliedProduct.new(
        "https://example.net/tomato",
        name: "Tomato",
        description: "Awesome tomato",
        quantity: DataFoodConsortium::Connector::QuantitativeValue.new(
          unit: DfcLoader.connector.MEASURES.KILOGRAM,
          value: 2,
        ),
        productType: product_type,
      )
    end
    let(:product_type) { DfcLoader.connector.PRODUCT_TYPES.VEGETABLE.NON_LOCAL_VEGETABLE }
    let!(:taxon) { create(:taxon, name: "Non local vegetable", dfc_id: "non local vegetable") }

    it "creates a new Spree::Product" do
      product = builder.import_product(supplied_product)

      expect(product).to be_a(Spree::Product)
      expect(product.name).to eq("Tomato")
      expect(product.description).to eq("Awesome tomato")
      expect(product.variant_unit).to eq("weight")
    end

    describe "taxon" do
      it "assigns the taxon matching the DFC product type" do
        product = builder.import_product(supplied_product)

        expect(product.primary_taxon).to eq(taxon)
      end

      describe "when no matching taxon" do
        let(:product_type) { DfcLoader.connector.PRODUCT_TYPES.DRINK }

        it "set the taxon to nil" do
          product = builder.import_product(supplied_product)

          expect(product.primary_taxon).to be_nil
        end
      end
    end
  end
end
