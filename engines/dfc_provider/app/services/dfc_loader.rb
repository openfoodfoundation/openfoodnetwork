# frozen_string_literal: true

class DfcLoader
  def self.connector
    @connector ||= load_vocabularies
  end

  def self.load_vocabularies
    connector = DataFoodConsortium::Connector::Connector.instance
    connector.loadMeasures(read_file("measures"))
    connector.loadFacets(read_file("facets"))
    connector.loadProductTypes(read_file("productTypes"))
    connector
  end

  def self.read_file(name)
    JSON.parse(
      Rails.root.join("engines/dfc_provider/vendor/#{name}.json").read
    )
  end
end
