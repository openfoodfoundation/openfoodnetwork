# frozen_string_literal: true

class EnterpriseBuilder < DfcBuilder
  def self.enterprise(enterprise)
    variants = VariantFetcher.new(enterprise).scope.to_a
    catalog_items = variants.map(&method(:catalog_item))
    supplied_products = catalog_items.map(&:product)

    DataFoodConsortium::Connector::Enterprise.new(
      enterprise.name
    ).tap do |e|
      e.semanticId = urls.enterprise_url(enterprise.id)
      e.suppliedProducts = supplied_products
      e.catalogItems = catalog_items
    end
  end
end
