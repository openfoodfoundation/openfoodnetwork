# frozen_string_literal: true

FactoryBot.define do
  factory :shipping_category, class: Spree::ShippingCategory do
    initialize_with { DefaultShippingCategory.find_or_create }
  end
end
