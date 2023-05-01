# frozen_string_literal: true

FactoryBot.define do
  factory :voucher do
    enterprise { create(:distributor_enterprise) }
    amount { rand(200.0) }
  end
end
