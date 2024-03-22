# frozen_string_literal: true

class AddressBuilder < DfcBuilder
  def self.address(address)
    DfcProvider::Address.new(
      urls.address_url(address),
      street: address.address1,
      postalCode: address.zipcode,
      city: address.city,
      country: address.country.name,
      region: address.state.name
    )
  end
end
