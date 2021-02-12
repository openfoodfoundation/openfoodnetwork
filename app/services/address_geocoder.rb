# frozen_string_literal: true

class AddressGeocoder
  def initialize(address)
    @address = address
  end

  def geocode
    latitude, longitude = Geocoder.coordinates(geocode_address)

    return unless latitude.present? && longitude.present?

    address.update(latitude: latitude, longitude: longitude)
  end

  private

  attr_reader :address

  def geocode_address
    [
      address.address1,
      address.address2,
      address.zipcode,
      address.city,
      address.country.andand.name,
      address.state.andand.name
    ].select(&:present?).join(', ')
  end
end
