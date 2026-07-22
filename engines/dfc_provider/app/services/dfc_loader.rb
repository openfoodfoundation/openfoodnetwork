# frozen_string_literal: true

class DfcLoader
  LOCK = Mutex.new

  def self.connector
    @connector ||= LOCK.synchronize do
      @connector || DataFoodConsortium::ConnectorV1::Connector.instance.tap do |connector|
        connector.loadMeasures(read_file("measures"))
        connector.loadFacets(read_file("facets"))
        connector.loadProductTypes(read_file("productTypes"))
        load_thesaurus(connector, "vocabulary") # order states etc
      end
    end
  end

  def self.connector_v2
    @connector_v2 ||= LOCK.synchronize do
      @connector_v2 || DataFoodConsortium::Connector::Connector.instance.tap do |connector|
        connector.loadMeasures(read_file("measures"))
        connector.loadFacets(read_file("facets"))
        connector.loadProductTypes(read_file("productTypes"))
        load_thesaurus(connector, "vocabulary") # order states etc
      end
    end
  end

  def self.vocabulary(name)
    load_thesaurus(connector, name)
  end

  def self.load_thesaurus(connector, name)
    @vocabs ||= {}
    @vocabs[name] ||= connector.__send__(:loadThesaurus, read_file(name))
  end

  def self.read_file(name)
    JSON.parse(
      Rails.root.join("engines/dfc_provider/vendor/#{name}.json").read
    )
  end
end
