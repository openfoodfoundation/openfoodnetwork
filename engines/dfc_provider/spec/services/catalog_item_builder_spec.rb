# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe CatalogItemBuilder do
  let(:variant) { build(:variant) }

  describe ".catalog_item" do
    before do
      variant.id = 5
      variant.supplier_id = 7
    end

    it "assigns a semantic id" do
      item = CatalogItemBuilder.catalog_item(variant)

      expect(item.semanticId).to eq(
        "http://test.host/api/dfc/enterprises/7/catalog_items/5"
      )
    end

    it "refers to a supplied product" do
      item = CatalogItemBuilder.catalog_item(variant)

      expect(item.product.semanticId).to eq(
        "http://test.host/api/dfc/enterprises/7/supplied_products/5"
      )
    end

    it "refers to the supplier" do
      item = CatalogItemBuilder.catalog_item(variant)

      expect(item.managedBy).to eq(
        "http://test.host/api/dfc/enterprises/7"
      )
    end
  end

  describe ".apply_stock" do
    let(:item) { CatalogItemBuilder.catalog_item(variant) }

    it "updates from on-demand to out-of-stock" do
      variant.save!
      variant.on_demand = true
      variant.on_hand = -3

      item.stockLimitation = 0

      expect {
        CatalogItemBuilder.apply_stock(item, variant)
        variant.save!
      }
        .to change { variant.on_demand }.to(false)
        .and change { variant.on_hand }.to(0)
    end
  end
end
