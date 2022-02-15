# frozen_string_literal: true

FactoryBot.define do
  factory :customer, class: Customer do
    email { generate(:random_email) }
    enterprise
    code { SecureRandom.base64(150) }
    user
    bill_address { create(:address) }
  end
end
