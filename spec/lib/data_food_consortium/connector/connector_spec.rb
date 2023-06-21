# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('lib/data_food_consortium/connector/connector')

describe DataFoodConsortium::Connector::Connector, vcr: true do
  subject(:connector) { described_class.instance }
  let(:product) do
    DataFoodConsortium::Connector::SuppliedProduct.new(
      "https://example.net/tomato",
      name: "Tomato",
      description: "Awesome tomato"
    )
  end

  it "exports" do
    json = connector.export(product)
    expect(json).to match '"dfc-b:name":"Tomato"'
  end

  it "imports" do
    json = connector.export(product)
    result = connector.import(json)
    expect(result.class).to eq product.class
    expect(result.semanticType).to eq product.semanticType
    expect(result.semanticId).to eq "https://example.net/tomato"
    expect(result.name).to eq "Tomato"
  end

  it "imports from IO like Rails supplies it" do
    json = connector.export(product)
    io = StringIO.new(json)
    result = connector.import(io)

    expect(result.class).to eq product.class
    expect(result.semanticType).to eq product.semanticType
    expect(result.semanticId).to eq "https://example.net/tomato"
    expect(result.name).to eq "Tomato"
  end
end
