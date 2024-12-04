# frozen_string_literal: true

class DfcLoader
  def self.connector
    unless @connector
      @connector = DataFoodConsortium::Connector::Connector.instance
      load_context
      load_vocabularies
    end

    @connector
  end

  def self.load_context
    JSON::LD::Context.add_preloaded("http://www.datafoodconsortium.org/") {
      JSON::LD::Context.parse(read_file("context_1.8.2")["@context"])
    }
  end

  def self.vocabulary(name)
    @vocabs ||= {}
    @vocabs[name] ||= connector.__send__(:loadThesaurus, read_file(name))
  end

  def self.load_vocabularies
    connector.loadMeasures(read_file("measures"))
    connector.loadFacets(read_file("facets"))
    connector.loadProductTypes(read_file("productTypes"))
    vocabulary("vocabulary") # order states etc
  end

  def self.read_file(name)
    JSON.parse(
      Rails.root.join("engines/dfc_provider/vendor/#{name}.json").read
    )
  end
end
