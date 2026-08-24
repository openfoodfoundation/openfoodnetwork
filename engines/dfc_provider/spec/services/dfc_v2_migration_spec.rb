# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcV2Migration do
  describe "#up" do
    it "transforms an Enterprise to an Organization" do
      enterprise = DfcProvider::Enterprise.new(
        "example.com/api/dfc/enterprises/12",
        name: "Blueberry Bliss Farm",
      )
      result = subject.up(enterprise).first
      expect(result).to be_a DataFoodConsortium::Connector::Organization
      expect(result.semanticId).to eq "example.com/api/dfc/organizations/12"
      expect(result.name).to eq "Blueberry Bliss Farm"
    end

    it "transforms a Person" do
      person = DataFoodConsortium::ConnectorV1::Person.new("#p1")
      result = subject.up(person).first
      expect(result).to be_a DataFoodConsortium::Connector::Person
      expect(result.semanticId).to eq "#p1"
    end

    it "returns unknown objects unchanged" do
      objects = [
        1, 2, "skip a few", # ♪ ♪ ♫ ♪
        [], {}, Object.new,
      ]

      result = subject.up(*objects)

      expect(result).to eq objects
    end

    it "migrates nested values" do
      enterprise = DfcProvider::Enterprise.new(
        "example.com/api/dfc/enterprises/12",
        mainContact: DataFoodConsortium::ConnectorV1::Person.new(
          "example.com/api/dfc/enterprises/12#mainContact"
        ),
      )
      contact = subject.up(enterprise).first.mainContact
      expect(contact).to be_a DataFoodConsortium::Connector::Person
      expect(contact.semanticId).to eq "example.com/api/dfc/organizations/12#mainContact"
    end

    it "transforms objects without a semantic id" do
      value = DataFoodConsortium::ConnectorV1::QuantitativeValue.new(value: 3.0)
      expect(subject.up(value).first).to be_a DataFoodConsortium::Connector::QuantitativeValue
    end

    it "migrates objects referencing each other" do
      enterprise = DfcProvider::Enterprise.new("example.com/api/dfc/enterprises/12")
      person = DataFoodConsortium::ConnectorV1::Person.new(
        "example.com/api/dfc/enterprises/12#mainContact"
      )
      enterprise.mainContact = person
      person.affiliatedOrganizations << enterprise

      organization = subject.up(enterprise).first

      expect(organization.mainContact.affiliatedOrganizations.first).to equal organization
    end
  end

  describe "#up_generic" do
    it "copies all available attributes" do
      person = DataFoodConsortium::ConnectorV1::Person.new(
        "#p1",
        firstName: "Jane",
      )
      result = subject.up_generic(person)
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
      result = subject.up_generic(person, "#jac", firstName: "J")
      expect(result.semanticId).to eq "#jac"
      expect(result.firstName).to eq "J"
      expect(result.lastName).to eq "Jackson"
    end

    it "returns unavailable classes unchanged" do
      object = DataFoodConsortium::ConnectorV1::Quantity.new(
        unit: "Unit",
        value: "Value",
      )
      result = subject.up_generic(object)
      expect(result).to equal object
    end
  end
end
