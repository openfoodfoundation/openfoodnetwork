# frozen_string_literal: true

class DfcLoader
  def self.connector
    unless @connector
      @connector = DataFoodConsortium::ConnectorV1::Connector.instance
      @connector.loadMeasures(read_file("measures"))
      @connector.loadFacets(read_file("facets"))
      @connector.loadProductTypes(read_file("productTypes"))
      vocabulary("vocabulary") # order states etc
    end

    @connector
  end

  def self.connector_v2
    unless @connector_v2
      @connector_v2 = DataFoodConsortium::Connector::Connector.instance
      @connector_v2.loadMeasures(read_file("measures"))
      @connector_v2.loadFacets(read_file("facets"))
      @connector_v2.loadProductTypes(read_file("productTypes"))
      vocabulary("vocabulary") # order states etc
    end

    @connector_v2
  end

  def self.vocabulary(name)
    @vocabs ||= {}
    @vocabs[name] ||= connector.__send__(:loadThesaurus, read_file(name))
  end

  def self.read_file(name)
    JSON.parse(
      Rails.root.join("engines/dfc_provider/vendor/#{name}.json").read
    )
  end
end
