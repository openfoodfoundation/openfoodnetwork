# frozen_string_literal: true

class AddressBuilder < DfcBuilder
  def self.address(address)
    DataFoodConsortium::Connector::Address.new(
      urls.address_url(address),
      street: address.address1,
      postalCode: address.zipcode,
      city: address.city,
      country: address.country.name
    )
  end
end
