# frozen_string_literal: true

FactoryBot.define do
  factory :zone, class: Spree::Zone do
    name { generate(:random_string) }
    description { generate(:random_string) }
  end

  factory :zone_with_member, parent: :zone do
    default_tax { true }

    after(:create) do |zone|
      Spree::ZoneMember.create!(zone: zone, zoneable: Spree::Country.find_by(name: 'Australia'))
    end
  end
end
