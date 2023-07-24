# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('lib/data_food_consortium/connector/connector')

describe DataFoodConsortium::Connector::Importer, vcr: true do
  let(:connector) { DataFoodConsortium::Connector::Connector.instance }
  let(:enterprise) do
    DataFoodConsortium::Connector::Enterprise.new(
      "https://example.net/foo-food-inc",
      suppliedProducts: [product, second_product],
    )
  end
  let(:catalog_item) do
    DataFoodConsortium::Connector::CatalogItem.new(
      "https://example.net/tomatoItem",
      product:,
    )
  end
  let(:product) do
    DataFoodConsortium::Connector::SuppliedProduct.new(
      "https://example.net/tomato",
      name: "Tomato",
      description: "Awesome tomato",
      totalTheoreticalStock: 3,
    )
  end
  let(:product_data) do
    <<~JSON
      {
        "@context":"http://static.datafoodconsortium.org/ontologies/context.json",
        "@id":"https://example.net/tomato",
        "@type":"dfc-b:SuppliedProduct",
        "dfc-b:name":"Tomato",
        "dfc-b:description":"Awesome tomato",
        "dfc-b:alcoholPercentage":0.0,
        "dfc-b:lifetime":"",
        "dfc-b:usageOrStorageCondition":"",
        "dfc-b:totalTheoreticalStock":3
      }
    JSON
  end
  let(:product_data_with_context) do
    <<~JSON
      {
        "@context": {
          "dfc-b": "http://static.datafoodconsortium.org/ontologies/DFC_BusinessOntology.owl#",
          "dfc-m": "http://static.datafoodconsortium.org/data/measures.rdf#",
          "dfc-pt": "http://static.datafoodconsortium.org/data/productTypes.rdf#"
        },
        "@id":"https://example.net/tomato",
        "@type":"dfc-b:SuppliedProduct",
        "dfc-b:name":"Tomato",
        "dfc-b:description":"Awesome tomato",
        "dfc-b:alcoholPercentage":0.0,
        "dfc-b:lifetime":"",
        "dfc-b:usageOrStorageCondition":"",
        "dfc-b:totalTheoreticalStock":3
      }
    JSON
  end
  let(:product_data_with_context_v1_8) do
    <<~JSON
      {
        "@context": {
          "dfc-b": "https://github.com/datafoodconsortium/ontology/releases/latest/download/DFC_BusinessOntology.owl#",
          "dfc-m": "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/measures.rdf#",
          "dfc-pt": "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#"
        },
        "@id":"https://example.net/tomato",
        "@type":"dfc-b:SuppliedProduct",
        "dfc-b:name":"Tomato",
        "dfc-b:description":"Awesome tomato",
        "dfc-b:alcoholPercentage":0.0,
        "dfc-b:lifetime":"",
        "dfc-b:usageOrStorageCondition":"",
        "dfc-b:totalTheoreticalStock":3
      }
    JSON
  end
  let(:second_product) do
    DataFoodConsortium::Connector::SuppliedProduct.new(
      "https://example.net/ocra",
      name: "Ocra",
    )
  end
  let(:quantity) do
    DataFoodConsortium::Connector::QuantitativeValue.new(
      unit: piece,
      value: 5,
    )
  end
  let(:piece) do
    unless connector.MEASURES.respond_to?(:UNIT)
      connector.loadMeasures(read_file("measures"))
    end
    connector.MEASURES.UNIT.QUANTITYUNIT.PIECE
  end

  it "imports a single object with simple properties" do
    result = import(product)

    expect(result.class).to eq product.class
    expect(result.semanticType).to eq product.semanticType
    expect(result.semanticId).to eq "https://example.net/tomato"
    expect(result.name).to eq "Tomato"
    expect(result.description).to eq "Awesome tomato"
    expect(result.totalTheoreticalStock).to eq 3
  end

  it "imports an object with referenced context" do
    result = connector.import(product_data)

    expect(result.class).to eq DataFoodConsortium::Connector::SuppliedProduct
    expect(result.semanticType).to eq "https://github.com/datafoodconsortium/ontology/releases/latest/download/DFC_BusinessOntology.owl#SuppliedProduct"
    expect(result.semanticId).to eq "https://example.net/tomato"
    expect(result.name).to eq "Tomato"
    expect(result.description).to eq "Awesome tomato"
    expect(result.totalTheoreticalStock).to eq 3
  end

  it "imports an object with included context" do
    result = connector.import(product_data_with_context)

    expect(result.class).to eq DataFoodConsortium::Connector::SuppliedProduct
    expect(result.semanticType).to eq "https://github.com/datafoodconsortium/ontology/releases/latest/download/DFC_BusinessOntology.owl#SuppliedProduct"
    expect(result.semanticId).to eq "https://example.net/tomato"
    expect(result.name).to eq "Tomato"
    expect(result.description).to eq "Awesome tomato"
    expect(result.totalTheoreticalStock).to eq 3
  end

  it "imports an object with DFC v1.8 context" do
    result = connector.import(product_data_with_context_v1_8)

    expect(result.class).to eq DataFoodConsortium::Connector::SuppliedProduct
    expect(result.semanticType).to eq "https://github.com/datafoodconsortium/ontology/releases/latest/download/DFC_BusinessOntology.owl#SuppliedProduct"
    expect(result.semanticId).to eq "https://example.net/tomato"
    expect(result.name).to eq "Tomato"
    expect(result.description).to eq "Awesome tomato"
    expect(result.totalTheoreticalStock).to eq 3
  end

  it "imports a graph with multiple objects" do
    result = import(catalog_item, product)

    expect(result).to be_a Array
    expect(result.size).to eq 2

    item, tomato = result

    expect(item.class).to eq catalog_item.class
    expect(item.semanticType).to eq catalog_item.semanticType
    expect(item.semanticId).to eq "https://example.net/tomatoItem"
    expect(tomato.name).to eq "Tomato"
    expect(tomato.description).to eq "Awesome tomato"
    expect(tomato.totalTheoreticalStock).to eq 3
  end

  it "imports a graph including anonymous objects" do
    product.quantity = quantity

    tomato, items = import(product)

    expect(tomato.name).to eq "Tomato"
    expect(tomato.quantity).to eq items
    expect(items.value).to eq 5
    expect(items.unit).to eq piece
  end

  it "imports properties with lists" do
    result = import(enterprise, product, second_product)

    expect(result.size).to eq 3

    enterprise, tomato, ocra = result

    expect(enterprise.suppliedProducts).to eq [tomato, ocra]
  end

  def import(*args)
    json = connector.export(*args)
    connector.import(json)
  end

  def read_file(name)
    JSON.parse(
      Rails.root.join("engines/dfc_provider/vendor/#{name}.json").read
    )
  end
end
