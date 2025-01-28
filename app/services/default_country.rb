# frozen_string_literal: true

class DefaultCountry
  def self.id
    country.id
  end

  # Two letter code defined in ISO-3166-1.
  def self.code
    # Changing ENV requires restarting the process.
    ENV.fetch("DEFAULT_COUNTRY_CODE", nil)
  end

  def self.country
    # When ENV changes on restart, this cache will be reset as well.
    @country ||= Spree::Country.find_by(iso: code) || Spree::Country.first
  end
end
