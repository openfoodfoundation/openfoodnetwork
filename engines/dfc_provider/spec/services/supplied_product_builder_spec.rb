# frozen_string_literal: true

require_relative "../spec_helper"

describe SuppliedProductBuilder do
  include FileHelper

  subject(:builder) { described_class }
  let(:variant) {
    build(:variant, id: 5).tap { |v| v.product.supplier_id = 7 }
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

    it "assigns a product type" do
      product = builder.supplied_product(variant)
      vegetable = DfcLoader.connector.PRODUCT_TYPES.VEGETABLE.NON_LOCAL_VEGETABLE

      expect(product.productType).to eq vegetable
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
end
