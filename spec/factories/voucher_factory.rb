# frozen_string_literal: true

FactoryBot.define do
  factory :voucher, class: Voucher do
    enterprise { build(:distributor_enterprise) }
    amount { 10 }
  end

  factory :voucher_flat_rate, parent: :voucher, class: Vouchers::FlatRate do
    amount { 15 }
  end
end
