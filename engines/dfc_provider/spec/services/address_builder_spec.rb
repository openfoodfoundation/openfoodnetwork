# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe AddressBuilder do
  subject(:result) { described_class.address(address) }
  let(:address) {
    build(
      :address,
      id: 1, address1: "Paradise 15", zipcode: "0001", city: "Goosnargh",
      state: build(:state, name: "Victoria")
    )
  }

  describe ".address" do
    it "assigns a semantic id" do
      expect(result.semanticId).to eq(
        "http://test.host/api/dfc/addresses/1"
      )
    end

    it "assigns a street" do
      expect(result.street).to eq "Paradise 15"
    end

    it "assigns a postal code" do
      expect(result.postalCode).to eq "0001"
    end

    it "assigns a city" do
      expect(result.city).to eq "Goosnargh"
    end

    it "assigns a country" do
      expect(result.country).to eq "Australia"
    end

    it "assigns a region" do
      expect(result.region).to eq "Victoria"
    end
  end
end
