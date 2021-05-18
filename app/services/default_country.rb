class DefaultCountry
  def self.id
    DefaultCountry.country.id
  end

  def self.code
    DefaultCountry.country.iso
  end

  def self.country
    Spree::Country.find_by(iso: ENV["DEFAULT_COUNTRY_CODE"]) || Spree::Country.first
  end

  def self.id=(id)
    ENV["DEFAULT_COUNTRY_CODE"] = Spree::Country.find(id).iso
  end

  def self.code=(code)
    country = Spree::Country.find_by(iso: code) || Spree::Country.first
    ENV["DEFAULT_COUNTRY_CODE"] = country.iso
  end
end
