# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcLoader do
  it "prepares the DFC Connector to provide DFC object classes for export" do
    tomato = DataFoodConsortium::ConnectorV1::SuppliedProduct.new(
      "https://openfoodnetwork.org/tomato",
      name: "Tomato",
      description: "Awesome tomato",
    )

    expect(tomato.name).to eq "Tomato"
    expect(tomato.description).to eq "Awesome tomato"

    json = DfcIo.export(tomato)
    result = JSON.parse(json)

    expect(result.keys).to include(
      *%w(@context @type dfc-b:name dfc-b:description)
    )
    expect(result["dfc-b:name"]).to eq "Tomato"
  end

  it "loads vocabularies" do
    terms = DfcLoader.vocabulary("vocabulary")
    expect(terms.STATES.ORDERSTATE.HELD.semanticId)
      .to eq "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/vocabulary.rdf#Held"
  end

  it "loads vocabularies for v2" do
    connector = DfcLoader.connector_v2
    expect(connector.PRODUCT_TYPES.DRINK.semanticId).to end_with "#drink"
  end

  it "retries loading when the first attempt fails" do
    DfcLoader.instance_variable_set(:@connector, nil)

    calls = 0
    allow(DfcLoader).to receive(:read_file).and_wrap_original do |original, name|
      calls += 1
      raise Errno::ENOENT, name if calls == 1

      original.call(name)
    end

    expect { DfcLoader.connector }.to raise_error(Errno::ENOENT)

    # A failed load used to leave a memoised connector with empty MEASURES
    # behind, so later requests crashed with NoMethodError on Array.
    expect(DfcLoader.connector.MEASURES.PIECE).not_to be_nil
  end
end
