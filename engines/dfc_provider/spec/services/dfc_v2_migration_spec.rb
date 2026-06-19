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

    it "returns unknown objects unchanged" do
      objects = [
        1, 2, "skip a few", # ♪ ♪ ♫ ♪
        [], {}, Object.new,
      ]

      result = DfcV2Migration.up(*objects)

      expect(result).to eq objects
    end
  end

  describe ".up_generic" do
    it "copies all available attributes" do
      person = DataFoodConsortium::ConnectorV1::Person.new(
        "#p1",
        firstName: "Jane",
      )
      result = DfcV2Migration.up_generic(person)
      expect(result.semanticId).to eq "#p1"
      expect(result.firstName).to eq "Jane"
      expect(result.lastName).to eq nil
    end

    it "allows to define attributes" do
      person = DataFoodConsortium::ConnectorV1::Person.new(
        "#p1",
        firstName: "Jane",
        lastName: "Jackson",
      )
      result = DfcV2Migration.up_generic(person, "#jac", firstName: "J")
      expect(result.semanticId).to eq "#jac"
      expect(result.firstName).to eq "J"
      expect(result.lastName).to eq "Jackson"
    end
  end
end
