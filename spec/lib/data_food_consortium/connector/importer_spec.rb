# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('lib/data_food_consortium/connector/connector')

describe DataFoodConsortium::Connector::Importer, vcr: true do
  let(:connector) { DataFoodConsortium::Connector::Connector.instance }
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

  it "imports a single object with simple properties" do
    result = import(product)

    expect(result.class).to eq product.class
    expect(result.semanticType).to eq product.semanticType
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

  def import(*args)
    json = connector.export(*args)
    connector.import(json)
  end
end
