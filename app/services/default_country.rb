# frozen_string_literal: true

class DefaultCountry
  def self.id
    country.id
  end

  def self.code
    country.iso
  end

  def self.country
    Spree::Country.cached_find_by(iso: ENV.fetch("DEFAULT_COUNTRY_CODE",
                                                 nil)) || Spree::Country.first
  end
end
