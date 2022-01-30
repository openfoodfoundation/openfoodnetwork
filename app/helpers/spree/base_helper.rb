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

    def countries
      available_countries.map { |c| [c.name, c.id] }
    end

    def states_for_country(country)
      country.states.map do |state|
        [state.name, state.id]
      end
    end

    def countries_with_states
      available_countries.map { |c|
        [c.id, c.states.map { |s|
          [s.name, s.id]
        }]
      }
    end

    def pretty_time(time)
      [I18n.l(time.to_date, format: :long),
       time.strftime("%l:%M %p")].join(" ")
    end
  end
end
