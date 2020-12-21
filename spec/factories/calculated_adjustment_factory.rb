# frozen_string_literal: true

FactoryBot.define do
  factory :calculator_flat_rate, class: Calculator::FlatRate do
    preferred_amount { generate(:calculator_amount) }
  end
end
