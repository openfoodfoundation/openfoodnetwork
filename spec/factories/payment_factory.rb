# frozen_string_literal: true

FactoryBot.define do
  factory :payment, class: Spree::Payment do
    transient do
      distributor {
        order.distributor ||
          Enterprise.is_distributor.first ||
          FactoryBot.create(:distributor_enterprise)
      }
    end

    amount { 45.75 }
    association(:source, factory: :credit_card)
    order
    state { 'checkout' }
    response_code { nil }

    payment_method { FactoryBot.create(:payment_method, distributors: [distributor]) }
  end

  trait :completed do
    state { 'completed' }
    captured_at { Time.zone.now }
  end

  factory :check_payment, class: Spree::Payment do
    amount { 45.75 }
    payment_method
    order
  end
end
