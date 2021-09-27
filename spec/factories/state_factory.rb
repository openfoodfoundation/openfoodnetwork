# frozen_string_literal: true

FactoryBot.define do
  factory :state, class: Spree::State do
    name { "Victoria" }
    abbr { "Vic" }
    country
  end
end
