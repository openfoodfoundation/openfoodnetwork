# frozen_string_literal: true

FactoryBot.define do
  factory :state, class: Spree::State do
    name { 'Alabama' }
    abbr { 'AL' }
    country do |country|
      if usa = Spree::Country.find_by(numcode: 840)
        country = usa
      else
        country.association(:country)
      end
    end
  end
end
