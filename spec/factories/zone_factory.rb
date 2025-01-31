# frozen_string_literal: true

FactoryBot.define do
  factory :zone, aliases: [:zone_with_member], class: Spree::Zone do
    sequence(:name) { |n| "#{generate(:random_string)}#{n}" }
    description { generate(:random_string) }
    default_tax { true }
    zone_members { [Spree::ZoneMember.new(zoneable: member)] }

    transient do
      member { Spree::Country.find_by(name: "Australia") }
    end
  end

  factory :zone_with_state_member, parent: :zone do
    member { Spree::State.find_by(name: "Victoria") }
  end
end
