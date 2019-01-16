attach_per_item_trait = proc do
  trait :per_item do
    transient { amount 1 }
    calculator { build(:calculator_per_item, preferred_amount: amount) }
  end
end

FactoryBot.modify do
  factory :payment_method, &attach_per_item_trait
  factory :shipping_method, &attach_per_item_trait
  factory :enterprise_fee, &attach_per_item_trait
end
