# frozen_string_literal: true

module Spree
  module BaseHelper
    def available_countries
      checkout_zone = Zone.find_by(name: Spree::Config[:checkout_zone])

      countries = if checkout_zone && checkout_zone.kind == 'country'
                    checkout_zone.countries
                  else
                    Country.includes(:states).all
                  end

      countries.collect do |country|
        country.name = Spree.t(country.iso, scope: 'country_names', default: country.name)
        country
      end.sort { |a, b| a.name <=> b.name }
    end

    def pretty_time(time)
      [I18n.l(time.to_date, format: :long),
       time.strftime("%l:%M %p")].join(" ")
    end
  end
end
