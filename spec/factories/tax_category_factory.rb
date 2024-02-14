# frozen_string_literal: true

FactoryBot.define do
  factory :tax_category, class: Spree::TaxCategory do
    sequence(:name) { |n| "TaxCategory - #{n}" }
    description { generate(:random_string) }
  end
end
