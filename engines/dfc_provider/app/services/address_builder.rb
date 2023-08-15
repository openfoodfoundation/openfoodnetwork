# frozen_string_literal: true

class AddressBuilder < DfcBuilder
  def self.address(address)
    # TODO add url helper/address contoller so we can do urls.address_url(address.id)
    DataFoodConsortium::Connector::Address.new(
      "http://test.host/api/dfc-v1.7/address/#{address.id}",
      street: address.address1,
      postalCode: address.zipcode,
      city: address.city,
      country: address.country.name
    )
  end
end
