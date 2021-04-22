# frozen_string_literal: true

FactoryBot.define do
  factory :tax_rate, class: Spree::TaxRate do
    zone
    amount { 0.1 }
    tax_category
    association(:calculator, factory: :default_tax_calculator, strategy: :build)
  end
end
