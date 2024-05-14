# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcBuilder do
  let(:variant) { build(:variant) }

  describe ".catalog_item" do
    it "assigns a semantic id" do
      variant.id = 5
      variant.product.supplier_id = 7

      item = DfcBuilder.catalog_item(variant)

      expect(item.semanticId).to eq(
        "http://test.host/api/dfc/enterprises/7/catalog_items/5"
      )
    end

    it "refers to a supplied product" do
      variant.id = 5
      variant.product.supplier_id = 7

      item = DfcBuilder.catalog_item(variant)

      expect(item.product.semanticId).to eq(
        "http://test.host/api/dfc/enterprises/7/supplied_products/5"
      )
    end
  end
end
