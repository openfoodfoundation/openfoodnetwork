# frozen_string_literal: true

FactoryBot.define do
  factory :country, class: Spree::Country do
    iso_name { "AUSTRALIA" }
    name { "Australia" }
    iso { "AU" }
    iso3 { "AUS" }
    numcode { 36 }
  end
end
