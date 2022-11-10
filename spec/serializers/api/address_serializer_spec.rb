# frozen_string_literal: true

require 'spec_helper'

describe Api::AddressSerializer do
  subject(:serializer) { described_class.new(address) }
  let(:address) { build(:address) }

  describe "#country_name" do
    it "provides the country's name" do
      address.country.name = "Australia"
      expect(serializer.country_name).to eq "Australia"
    end
  end

  describe "#state_name" do
    it "provides the state's abbreviation" do
      address.state.abbr = "Vic"
      expect(serializer.state_name).to eq "Vic"
    end
  end

  describe "caching" do
    it "updates with the record" do
      expect {
        address.update!(first_name: "Nick")
      }.to change {
        serializer.to_json
      }
    end

    it "uses stored result when database wasn't changed" do
      expect {
        address.first_name = "Nick"
      }.to_not change {
        serializer.to_json
      }
    end
  end
end
