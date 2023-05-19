# frozen_string_literal: true

FactoryBot.define do
  factory :voucher do
    enterprise { build(:distributor_enterprise) }
    amount { 15 }
  end
end
