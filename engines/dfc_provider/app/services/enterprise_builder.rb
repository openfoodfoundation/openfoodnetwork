# frozen_string_literal: true

class EnterpriseBuilder < DfcBuilder
  def self.enterprise(enterprise)
    variants = enterprise.supplied_variants.to_a
    catalog_items = variants.map(&method(:catalog_item))
    supplied_products = catalog_items.map(&:product)
    address = AddressBuilder.address(enterprise.address)

    DataFoodConsortium::Connector::Enterprise.new(
      urls.enterprise_url(enterprise.id),
      name: enterprise.name,
      description: enterprise.description,
      vatNumber: enterprise.abn,
      suppliedProducts: supplied_products,
      catalogItems: catalog_items
    ).tap do |e|
      e.addLocalization(address)
    end
  end

  def self.enterprise_group(group)
    DataFoodConsortium::Connector::Enterprise.new(
      urls.enterprise_group_url(group.id),
      name: group.name,
      description: group.description,
    )
  end
end
