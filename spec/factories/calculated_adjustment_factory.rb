FactoryBot.define do
  factory :calculator_flat_rate, class: Calculator::FlatRate do
    preferred_amount { generate(:calculator_amount) }
  end
end

FactoryBot.modify do
  attach_calculator_traits = proc do
    trait :flat_rate do
      transient { amount 1 }
      calculator { build(:calculator_flat_rate, preferred_amount: amount) }
    end

    trait :per_item do
      transient { amount 1 }
      calculator { build(:calculator_per_item, preferred_amount: amount) }
    end
  end

  factory :payment_method, &attach_calculator_traits
  factory :shipping_method, &attach_calculator_traits
  factory :enterprise_fee, &attach_calculator_traits
end
