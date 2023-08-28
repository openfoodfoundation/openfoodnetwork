# frozen_string_literal: true

require_relative "../spec_helper"

describe DfcIo do
  let(:person) do
    DataFoodConsortium::Connector::Person.new("Pete")
  end
  let(:enterprise) do
    DataFoodConsortium::Connector::Enterprise.new("Pete's Pumpkins")
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
  end
end
