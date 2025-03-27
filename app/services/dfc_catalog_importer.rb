# frozen_string_literal: true

class DfcCatalogImporter
  def self.reset_variant(variant)
    if variant.on_demand
      variant.on_demand = false
    else
      variant.on_hand = 0
    end
  end

  attr_reader :catalog, :existing_variants

  def initialize(existing_variants, catalog)
    @existing_variants = existing_variants
    @catalog = catalog
  end

  # Reset stock for any variants that were removed from the catalog.
  #
  # When variants are removed from the remote catalog, we can't place
  # backorders for them anymore. If our copy of the product has limited
  # stock then we need to set the stock to zero to prevent any more sales.
  #
  # But if our product is on-demand/backorderable then our stock level is
  # a representation of remaining local stock. We then need to limit sales
  # to this local stock and set on-demand to false.
  #
  # We don't delete the variant because it may come back at a later time and
  # we don't want to lose the connection to previous orders.
  def reset_absent_variants
    absent_variants.map do |variant|
      self.class.reset_variant(variant)
    end
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
