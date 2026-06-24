# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcV2Migration do
  describe ".up" do
    it "transforms an Enterprise to an Organization" do
      enterprise = DfcProvider::Enterprise.new(
        "example.com/api/dfc/enterprises/12",
        name: "Blueberry Bliss Farm",
      )
      result = DfcV2Migration.up(enterprise).first
      expect(result).to be_a DataFoodConsortium::Connector::Organization
      expect(result.semanticId).to eq "example.com/api/dfc/organizations/12"
      expect(result.name).to eq "Blueberry Bliss Farm"
    end

    it "transforms a Person" do
      person = DataFoodConsortium::ConnectorV1::Person.new("#p1")
      result = DfcV2Migration.up(person).first
      expect(result).to be_a DataFoodConsortium::Connector::Person
      expect(result.semanticId).to eq "#p1"
    end

    it "returns everything else unchanged" do
      address = DataFoodConsortium::ConnectorV1::Address.new("#a1")
      result = DfcV2Migration.up(address).first
      expect(result).to be_a DataFoodConsortium::ConnectorV1::Address
      expect(result).to eq address
    end
  end
end
