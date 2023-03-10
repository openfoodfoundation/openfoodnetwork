# frozen_string_literal: true

class EnterpriseBuilder < DfcBuilder
  def self.enterprise(enterprise)
    DataFoodConsortium::Connector::Enterprise.new(
      enterprise.name
    ).tap do |e|
      e.semanticId = urls.enterprise_url(enterprise.id)
      e.catalogItems = catalog_items(enterprise)
    end
  end

  def self.catalog_items(enterprise)
    VariantFetcher.new(enterprise).scope.to_a.map do |variant|
      catalog_item(variant)
    end
  end
end
