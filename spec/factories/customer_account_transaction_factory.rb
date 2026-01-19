# frozen_string_literal: true

FactoryBot.define do
  factory :customer_account_transaction do
    customer { build(:customer) }
    amount { 10.00 }
    currency { "AUD" }
    payment_method { build(:payment_method) }
  end
end
