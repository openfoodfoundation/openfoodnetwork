# frozen_string_literal: true

# Our internal data structures are different to the API data strurctures.
module AddressTransformation
  extend ActiveSupport::Concern

  def transform_address!(attributes, from, to)
    return unless attributes.key?(from)

    address = attributes.delete(from)

    if address.nil?
      attributes[to] = nil
      return
    end

    address.transform_keys! do |key|
      {
        phone: :phone, latitude: :latitude, longitude: :longitude,
        first_name: :firstname, last_name: :lastname,
        street_address_1: :address1, street_address_2: :address2,
        postal_code: :zipcode,
        locality: :city,
        region: :state,
        country: :country,
      }.with_indifferent_access[key]
    end

    address[:state] = find_state(address) if address[:state].present?
    address[:country] = find_country(address) if address[:country].present?

    attributes["#{to}_attributes"] = address
  end

  private

  def find_state(address)
    Spree::State.find_by("LOWER(abbr) = ? OR LOWER(name) = ?",
                         address.dig(:state, :code)&.downcase,
                         address.dig(:state, :name)&.downcase)
  end

  def find_country(address)
    Spree::Country.find_by("LOWER(iso) = ? OR LOWER(name) = ?",
                           address.dig(:country, :code)&.downcase,
                           address.dig(:country, :name)&.downcase)
  end
end
