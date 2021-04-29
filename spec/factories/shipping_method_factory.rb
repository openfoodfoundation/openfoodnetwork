# frozen_string_literal: true

FactoryBot.define do
  factory :base_shipping_method, class: Spree::ShippingMethod do
    zones { [] }
    name { 'UPS Ground' }

    distributors { [Enterprise.is_distributor.first || FactoryBot.create(:distributor_enterprise)] }
    display_on { '' }

    before(:create) do |shipping_method, _evaluator|
      shipping_method.shipping_categories << DefaultShippingCategory.find_or_create
    end

    trait :flat_rate do
      transient { amount { 1 } }
      calculator { build(:calculator_flat_rate, preferred_amount: amount) }
    end

    trait :per_item do
      transient { amount { 1 } }
      calculator { build(:calculator_per_item, preferred_amount: amount) }
    end

    factory :shipping_method, class: Spree::ShippingMethod do
      association(:calculator, factory: :calculator, strategy: :build)
    end

    factory :free_shipping_method, class: Spree::ShippingMethod do
      association(:calculator, factory: :no_amount_calculator, strategy: :build)
    end
  end

  factory :shipping_method_with, parent: :shipping_method do
    trait :delivery do
      require_ship_address { true }
    end

    trait :pickup do
      require_ship_address { false }
    end

    trait :flat_rate do
      transient { amount { 50.0 } }
      calculator { Calculator::FlatRate.new(preferred_amount: amount) }
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
        shipping_fee { 3 }
      end

      calculator { build(:calculator_per_item, preferred_amount: shipping_fee) }
      require_ship_address { false }
      distributors { [create(:distributor_enterprise_with_tax)] }
    end
  end
end
