# frozen_string_literal: true

class EnterpriseBuilder < DfcBuilder
  def self.enterprise(enterprise)
    variants = VariantFetcher.new(enterprise).scope.to_a
    supplied_products = variants.map(&method(:supplied_product))
    catalog_items = variants.map(&method(:catalog_item))

    DataFoodConsortium::Connector::Enterprise.new(
      enterprise.name
    ).tap do |e|
      e.semanticId = urls.enterprise_url(enterprise.id)
      e.suppliedProducts = supplied_products
      e.catalogItems = catalog_items
    end
  end
end
