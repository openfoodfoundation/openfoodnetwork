# frozen_string_literal: true

require_relative "../spec_helper"

# Exporting a catalog and importing it again should preserve product data.
#
# Our unit specs build DFC objects in Ruby and therefore don't notice when
# our serialised JSON-LD is missing a link between those objects. Here we
# serialise like the CatalogItems endpoint does and parse the result again.
RSpec.describe "DFC catalog round trip" do
  subject(:imported_variant) do
    SuppliedProductImporter.import_variant(imported_product, enterprise)
  end

  let(:enterprise) { create(:supplier_enterprise) }
  let(:imported_product) { DfcCatalog.from_json(catalog_json).products.first }
  # Serialise like DfcProvider::CatalogItemsController#index does.
  let(:catalog_json) do
    items = [CatalogItemBuilder.catalog_item(variant)]
    DfcIo.export(
      *items,
      *items.map(&:product),
      *items.map(&:product).flat_map(&:isVariantOf),
      *items.flat_map(&:offers),
    )
  end

  describe "stock controlled variant" do
    let(:variant) do
      create(:variant, enterprise:, price: 14.99, on_demand: false, on_hand: 7)
    end

    it "preserves the price" do
      expect(imported_variant.price).to eq 14.99
    end

    it "preserves the stock level" do
      imported_variant.save!

      expect(imported_variant.on_demand).to eq false
      expect(imported_variant.on_hand).to eq 7
    end
  end

  describe "on-demand variant" do
    let(:variant) do
      create(:variant, enterprise:, price: 3.50, on_demand: true)
    end

    it "preserves the price" do
      expect(imported_variant.price).to eq 3.50
    end
  end
end
