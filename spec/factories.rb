# frozen_string_literal: true

require 'ffaker'

FactoryBot.define do
  sequence(:random_string)      { FFaker::Lorem.sentence }
  sequence(:random_description) { FFaker::Lorem.paragraphs(Kernel.rand(1..5)).join("\n") }
  sequence(:random_email)       { FFaker::Internet.email }

  factory :exchange, class: Exchange do
    incoming    { false }
    order_cycle { OrderCycle.first || FactoryBot.create(:simple_order_cycle) }
    sender      { incoming ? FactoryBot.create(:enterprise) : order_cycle.coordinator }
    receiver    { incoming ? order_cycle.coordinator : FactoryBot.create(:enterprise) }
  end

  factory :schedule, class: Schedule do
    sequence(:name) { |n| "Schedule #{n}" }

    transient do
      order_cycles { [OrderCycle.first || create(:simple_order_cycle)] }
    end

    before(:create) do |schedule, evaluator|
      evaluator.order_cycles.each do |order_cycle|
        order_cycle.schedules << schedule
      end
    end
  end

  factory :proxy_order, class: ProxyOrder do
    subscription
    order_cycle { subscription.order_cycles.first }
    before(:create) do |proxy_order, _proxy|
      proxy_order.order&.update_attribute(:order_cycle_id, proxy_order.order_cycle_id)
    end
  end

  factory :variant_override, class: VariantOverride do
    price { 77.77 }
    on_demand { false }
    count_on_hand { 11_111 }
    default_stock { 2000 }
    resettable { false }

    trait :on_demand do
      on_demand { true }
      count_on_hand { nil }
    end

    trait :use_producer_stock_settings do
      on_demand { nil }
      count_on_hand { nil }
    end
  end

  factory :inventory_item, class: InventoryItem do
    enterprise
    variant
    visible { true }
  end

  factory :enterprise_relationship do
  end

  factory :enterprise_role do
  end

  factory :enterprise_group, class: EnterpriseGroup do
    name { 'Enterprise group' }
    sequence(:permalink) { |n| "group#{n}" }
    description { 'this is a group' }
    on_front_page { false }
    address { FactoryBot.build(:address) }
  end

  factory :enterprise_fee, class: EnterpriseFee do
    transient { amount { nil } }

    sequence(:name) { |n| "Enterprise fee #{n}" }
    sequence(:fee_type) { |n| EnterpriseFee::FEE_TYPES[n % EnterpriseFee::FEE_TYPES.count] }

    enterprise { Enterprise.first || FactoryBot.create(:supplier_enterprise) }
    calculator { build(:calculator_per_item, preferred_amount: amount) }

    after(:create) { |ef| ef.calculator.save! }

    trait :flat_rate do
      transient { amount { 1 } }
      calculator { build(:calculator_flat_rate, preferred_amount: amount) }
    end

    trait :per_item do
      transient { amount { 1 } }
      calculator { build(:calculator_per_item, preferred_amount: amount) }
    end
  end

  factory :adjustment_metadata, class: AdjustmentMetadata do
    adjustment { FactoryBot.create(:adjustment) }
    enterprise { FactoryBot.create(:distributor_enterprise) }
    fee_name { 'fee' }
    fee_type { 'packing' }
    enterprise_role { 'distributor' }
  end

  factory :producer_property, class: ProducerProperty do
    value { 'abc123' }
    producer { create(:supplier_enterprise) }
    property
  end

  factory :stripe_account do
    enterprise { FactoryBot.create(:distributor_enterprise) }
    stripe_user_id { "abc123" }
    stripe_publishable_key { "xyz456" }
  end
end
