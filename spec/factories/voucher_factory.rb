# frozen_string_literal: true

FactoryBot.define do
  factory :voucher_flat_rate, class: Voucher do
    enterprise { build(:distributor_enterprise) }
    voucher_type { Voucher::FLAT_RATE }
    amount { 15 }
  end

  factory :voucher_percentage, class: Voucher do
    enterprise { build(:distributor_enterprise) }
    voucher_type { Voucher::PERCENTAGE_RATE }
    amount { rand(1..100) }
  end
end
