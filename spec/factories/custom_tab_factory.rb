# frozen_string_literal: true

FactoryBot.define do
  factory :custom_tab do
    enterprise { build(:distributor_enterprise) }
    title { "MyString" }
    content { "MyText" }
  end
end
