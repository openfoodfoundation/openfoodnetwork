# frozen_string_literal: true

class DfcCatalogImporter
  attr_reader :catalog, :existing_variants

  def initialize(existing_variants, catalog)
    @existing_variants = existing_variants
    @catalog = catalog
  end

  def absent_variants
    present_ids = catalog.products.map(&:semanticId)
    catalog_url = FdcUrlBuilder.new(present_ids.first).catalog_url

    existing_variants
      .includes(:semantic_links).references(:semantic_links)
      .where.not(semantic_links: { semantic_id: present_ids })
      .select do |variant|
      # Variants that were in the same catalog before:
      variant.semantic_links.map(&:semantic_id).any? do |semantic_id|
        FdcUrlBuilder.new(semantic_id).catalog_url == catalog_url
      end
    end
  end
end
