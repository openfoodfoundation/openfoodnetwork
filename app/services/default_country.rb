# frozen_string_literal: true

class DefaultCountry
  def self.id
    country.id
  end

  def self.code
    country.iso
  end

  def self.country
    Spree::Country.find_by(iso: ENV["DEFAULT_COUNTRY_CODE"]) || Spree::Country.first
  end
end
