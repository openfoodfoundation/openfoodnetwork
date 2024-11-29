# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcIo do
  let(:person) do
    DataFoodConsortium::Connector::Person.new("Pete")
  end
  let(:enterprise) do
    DataFoodConsortium::Connector::Enterprise.new("Pete's Pumpkins")
  end
  let(:order) do
    DataFoodConsortium::Connector::Order.new("https://example.net", orderStatus: orderstate.HELD)
  end
  let(:orderstate) do
    DfcLoader.vocabulary("vocabulary").STATES.ORDERSTATE
  end

  describe ".export" do
    it "exports nothing" do
      expect(DfcIo.export).to eq ""
    end

    it "refers to the DFC context URI" do
      json = DfcIo.export(person)
      result = JSON.parse(json)

      expect(result["@context"]).to eq "https://www.datafoodconsortium.org"
    end

    it "uses the context to shorten URIs" do
      person.affiliatedOrganizations << enterprise

      json = DfcIo.export(person, enterprise)
      result = JSON.parse(json)

      expect(result["@graph"].count).to eq 2
      expect(result["@graph"].first.keys).to include(
        *%w(@id @type dfc-b:affiliates)
      )
    end

    it "recognises loaded vocabularies" do
      json = DfcIo.export(order)
      result = JSON.parse(json)

      expect(result["dfc-b:hasOrderStatus"]).to eq "dfc-v:Held"
    end
  end

  describe ".import" do
    it "recognises loaded vocabularies" do
      result = DfcIo.import(DfcIo.export(order))

      expect(result.orderStatus).to eq orderstate.HELD
    end
  end
end
