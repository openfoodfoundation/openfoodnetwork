# frozen_string_literal: true

FactoryBot.define do
  factory :asset, class: Spree::Asset do
    viewable { nil }
    position { 1 }
    type { "Spree::Image" }
  end
end
