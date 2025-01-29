# frozen_string_literal: true

class ProductTypeImporter < DfcBuilder
  # Try to find the taxon closest matching the given product type.
  # If we don't find any matching taxon, we return a random one.
  def self.taxon(product_type)
    priority_list = [product_type, *list_broaders(product_type)].compact

    # Optimistic querying.
    # We could query all broader taxons in one but then we need to still sort
    # them locally and use more memory. That would be a pessimistic query.
    # Consider caching the result instead.
    taxons = priority_list.lazy.map do |type|
      Spree::Taxon.find_by(dfc_id: type.semanticId)
    end.compact

    taxons.first || Spree::Taxon.first
  end

  def self.list_broaders(type)
    return [] if type.nil?

    broaders = type.broaders.map do |id|
      DataFoodConsortium::Connector::SKOSParser.concepts[id]
    end

    broaders + broaders.flat_map do |broader|
      list_broaders(broader)
    end
  end
end
