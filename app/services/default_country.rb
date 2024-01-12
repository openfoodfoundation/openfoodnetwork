# frozen_string_literal: true

class DefaultCountry
  def self.id
    country.id
  end

  def self.code
    country.iso
  end

  def self.country
    # Changing ENV requires restarting the process.
    iso = ENV.fetch("DEFAULT_COUNTRY_CODE", nil)

    # When ENV changes on restart, this cache will be reset as well.
    @country ||= Spree::Country.find_by(iso:) || Spree::Country.first
  end
end
