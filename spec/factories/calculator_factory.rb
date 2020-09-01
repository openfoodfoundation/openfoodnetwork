FactoryBot.define do
  factory :calculator, class: Calculator::FlatRate do
    after(:create) { |c| c.set_preference(:amount, 10.0) }
  end

  factory :no_amount_calculator, class: Calculator::FlatRate do
    after(:create) { |c| c.set_preference(:amount, 0) }
  end

  sequence(:calculator_amount)
  factory :calculator_per_item, class: Calculator::PerItem do
    preferred_amount { generate(:calculator_amount) }
  end

  factory :weight_calculator, class: Calculator::Weight do
    after(:build)  { |c| c.set_preference(:per_kg, 0.5) }
    after(:create) { |c| c.set_preference(:per_kg, 0.5); c.save! }
  end
end
