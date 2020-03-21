module Spree
  module BaseHelper
    # human readable list of variant options
    # Override: Do not show out of stock text
    def variant_options(v, _options = {})
      v.options_text
    end

    # Overriden to eager-load :states
    def available_countries
      checkout_zone = Zone.find_by_name(Spree::Config[:checkout_zone])

      countries = if checkout_zone && checkout_zone.kind == 'country'
                    checkout_zone.country_list
                  else
                    Country.includes(:states).all
                  end

      countries.collect do |country|
        country.name = Spree.t(country.iso, scope: 'country_names', default: country.name)
        country
      end.sort { |a, b| a.name <=> b.name }
    end
  end
end
