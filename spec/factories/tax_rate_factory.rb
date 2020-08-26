# frozen_string_literal: true

FactoryBot.define do
  factory :tax_rate, class: Spree::TaxRate do
    zone
    amount 100.00
    tax_category
  end
end
