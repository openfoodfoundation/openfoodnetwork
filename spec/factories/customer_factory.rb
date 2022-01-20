# frozen_string_literal: true

FactoryBot.define do
  factory :customer, class: Customer do
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    email { generate(:random_email) }
    enterprise
    code { SecureRandom.base64(150) }
    user
    bill_address { create(:address) }
  end
end
