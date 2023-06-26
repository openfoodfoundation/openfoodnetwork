# frozen_string_literal: true

require 'spec_helper'

describe AddressGeocoder do
  let(:australia) { Spree::Country.find_or_create_by!(name: "Australia") }
  let(:victoria) { Spree::State.find_or_create_by(name: "Victoria", country: australia) }
  let(:address) do
    create(:address,
           address1: "12 Galvin Street",
           address2: "Unit 1",
           city: "Altona",
           country: australia,
           state: victoria,
           zipcode: 3018,
           latitude: nil,
           longitude: nil)
  end

  it "formats the address into a single comma separated string when passing it to the geocoder" do
    expect(Geocoder).to receive(:coordinates)
      .with("12 Galvin Street, Unit 1, 3018, Altona, Australia, Victoria")

    AddressGeocoder.new(address).geocode
  end

  describe "when the geocoder can determine the latitude and longitude" do
    it "updates the address's latitude and longitude" do
      allow(Geocoder).to receive(:coordinates).and_return([-37.47, 144.78])

      AddressGeocoder.new(address).geocode

      expect(address.latitude).to eq(-37.47)
      expect(address.longitude).to eq(144.78)
    end
  end

  describe "when the geocoder cannot determine the latitude and longitude" do
    it "doesn't update the address's latitude and longitude" do
      allow(Geocoder).to receive(:coordinates).and_return([nil, nil])

      AddressGeocoder.new(address).geocode

      expect(address.latitude).to be_nil
      expect(address.longitude).to be_nil
    end
  end
end
