FactoryBot.define do
  factory :zone, class: Spree::Zone do
    name { generate(:random_string) }
    description { generate(:random_string) }
  end
end
