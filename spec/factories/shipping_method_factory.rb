FactoryBot.define do
  factory :shipping_method_with, parent: :shipping_method do
    trait :delivery do
      require_ship_address { true }
    end

    trait :pickup do
      require_ship_address { false }
    end

    trait :flat_rate do
      calculator { Calculator::FlatRate.new(preferred_amount: 50.0) }
    end

    trait :expensive_name do
      name { "Shipping" }
      description { "Expensive" }
      calculator { Calculator::FlatRate.new(preferred_amount: 100.55) }
    end

    trait :distributor do
      transient do
        distributor { create :enterprise }
      end
      distributors { [distributor] }
    end

    trait :shipping_fee do
      transient do
        shipping_fee 3
      end

      calculator { build(:calculator_per_item, preferred_amount: shipping_fee) }
      require_ship_address { false }
      distributors { [create(:distributor_enterprise_with_tax)] }
    end
  end
end

FactoryBot.modify do
  factory :shipping_method, parent: :base_shipping_method do
    distributors { [Enterprise.is_distributor.first || FactoryBot.create(:distributor_enterprise)] }
    display_on ''
    zones { [] }
  end
end
