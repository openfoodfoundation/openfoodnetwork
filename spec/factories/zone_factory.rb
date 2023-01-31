# frozen_string_literal: true

FactoryBot.define do
  factory :zone, class: Spree::Zone do
    name { generate(:random_string) }
    description { generate(:random_string) }
  end

  factory :zone_with_member, parent: :zone do
    transient do
      member { Spree::Country.find_by(name: "Australia") }
    end

    default_tax { true }
    zone_members { [Spree::ZoneMember.new(zoneable: member)] }
  end

  factory :zone_with_state_member, parent: :zone_with_member do
    member { Spree::State.find_by(name: "Victoria") }
  end
end
