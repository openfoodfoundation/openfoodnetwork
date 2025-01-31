# frozen_string_literal: true

module Addressing
  private

  def address(string)
    state = country.states.first
    parts = string.split(", ")
    Spree::Address.new(
      address1: parts[0],
      city: parts[1],
      zipcode: parts[2],
      state:,
      country:
    )
  end

  def zone
    zone = Spree::Zone.find_or_create_by(name: ENV.fetch('CHECKOUT_ZONE'))
    zone.members << Spree::ZoneMember.create(zoneable: country) unless
      zone.zoneables.include?(country)
    zone.save!
    zone
  end

  def country
    Spree::Country.find_by(iso: ENV.fetch('DEFAULT_COUNTRY_CODE'))
  end
end
