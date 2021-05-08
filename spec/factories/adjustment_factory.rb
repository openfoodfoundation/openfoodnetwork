# frozen_string_literal: true

FactoryBot.define do
  factory :adjustment, class: Spree::Adjustment do
    association(:adjustable, factory: :order)
    amount { 100.0 }
    label { 'Shipping' }
    eligible { true }
  end
end
