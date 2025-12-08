# frozen_string_literal: true

class AddressBuilder < DfcBuilder
  def self.address(address)
    DfcProvider::Address.new(
      urls.address_url(address),
      street: address.address1,
      postalCode: address.zipcode,
      city: address.city,
      country: country(address.country),
      region: address.state.name,
      latitude: address.latitude,
      longitude: address.longitude,
    )
  end

  # The country has to be a value of:
  # https://publications.europa.eu/resource/authority/country/0001
  def self.country(spree_country)
    code = spree_country.iso3
    "http://publications.europa.eu/resource/authority/country/#{code}"
  end
end
