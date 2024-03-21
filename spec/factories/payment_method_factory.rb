# frozen_string_literal: true

FactoryBot.define do
  factory :payment_method, class: Spree::PaymentMethod::Check do
    name { 'Check' }
    environment { 'test' }

    distributors { [Enterprise.is_distributor.first || FactoryBot.create(:distributor_enterprise)] }

    trait :flat_rate do
      transient { amount { 1 } }
      calculator { build(:calculator_flat_rate, preferred_amount: amount) }
    end

    trait :per_item do
      transient { amount { 1 } }
      calculator { build(:calculator_per_item, preferred_amount: amount) }
    end
  end

  factory :stripe_sca_payment_method, class: Spree::Gateway::StripeSCA do
    name { 'StripeSCA' }
    environment { 'test' }
    distributors { [FactoryBot.create(:stripe_account).enterprise] }
    preferred_enterprise_id { distributors.first.id }
  end

  factory :distributor_payment_method, class: DistributorPaymentMethod do
    distributor { FactoryBot.create(:distributor_enterprise) }
    payment_method { FactoryBot.create(:payment_method) }
  end
end
